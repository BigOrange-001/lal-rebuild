"""Pure version metadata and read-only Android manifest validation helpers."""

from __future__ import annotations

import re
import struct


_SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
_AXML_STRING_POOL = 0x0001
_AXML_START_ELEMENT = 0x0102
_UTF8_FLAG = 0x00000100


def release_metadata(version: str, swf_sha256: str) -> dict[str, str | int]:
    """Return the fixed AIR/Android version values used by ADT packaging."""
    match = _SEMVER.fullmatch(version)
    if not match:
        raise ValueError(f"unsupported project version: {version!r}")
    major, minor, patch = (int(value) for value in match.groups())
    if len(swf_sha256) != 64 or not re.fullmatch(r"[0-9a-fA-F]{64}", swf_sha256):
        raise ValueError("SWF SHA-256 must be 64 hexadecimal characters")
    version_code = major * 1_000_000 + minor * 1_000 + patch
    if not 1 <= version_code <= 2_100_000_000:
        raise ValueError("derived Android versionCode is outside the supported range")
    return {
        "version": version,
        "config_version": version,
        "version_code": version_code,
        "version_name": version,
        "air_version_number": version,
        "air_version_label": version,
    }


def _read_u16(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def _read_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def _decode_length8(data: bytes, offset: int) -> tuple[int, int]:
    first = data[offset]
    offset += 1
    if first & 0x80:
        return ((first & 0x7F) << 8) | data[offset], offset + 1
    return first, offset


def _decode_length16(data: bytes, offset: int) -> tuple[int, int]:
    first = _read_u16(data, offset)
    offset += 2
    if first & 0x8000:
        second = _read_u16(data, offset)
        return ((first & 0x7FFF) << 16) | second, offset + 2
    return first, offset


def _decode_string_pool(data: bytes, offset: int = 8) -> tuple[list[str], int]:
    if offset + 28 > len(data):
        raise ValueError("truncated AXML string pool header")
    chunk_type, header_size, chunk_size = struct.unpack_from("<HHI", data, offset)
    if chunk_type != _AXML_STRING_POOL or header_size < 28 or offset + chunk_size > len(data):
        raise ValueError("invalid AXML string pool chunk")
    string_count, style_count, flags, strings_start, _ = struct.unpack_from("<IIIII", data, offset + 8)
    if header_size + (string_count + style_count) * 4 > chunk_size:
        raise ValueError("invalid AXML string pool offsets")
    if strings_start < header_size + (string_count + style_count) * 4 or strings_start > chunk_size:
        raise ValueError("invalid AXML stringsStart")
    strings: list[str] = []
    for index in range(string_count):
        relative = _read_u32(data, offset + header_size + index * 4)
        position = offset + strings_start + relative
        if position >= offset + chunk_size:
            raise ValueError("AXML string offset is outside the string pool")
        if flags & _UTF8_FLAG:
            _, position = _decode_length8(data, position)
            byte_length, position = _decode_length8(data, position)
            end = position + byte_length
            if end >= offset + chunk_size or data[end] != 0:
                raise ValueError("unterminated AXML UTF-8 string")
            strings.append(data[position:end].decode("utf-8"))
        else:
            char_length, position = _decode_length16(data, position)
            end = position + char_length * 2
            if end + 2 > offset + chunk_size or data[end:end + 2] != b"\0\0":
                raise ValueError("unterminated AXML UTF-16 string")
            strings.append(data[position:end].decode("utf-16le"))
    return strings, offset + chunk_size


def _iter_axml_chunks(data: bytes, offset: int):
    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError("truncated AXML chunk header")
        chunk_type, header_size, chunk_size = struct.unpack_from("<HHI", data, offset)
        if header_size < 8 or chunk_size < header_size or offset + chunk_size > len(data):
            raise ValueError("invalid AXML chunk size")
        yield offset, chunk_type, header_size, chunk_size
        offset += chunk_size
    if offset != len(data):
        raise ValueError("AXML chunks do not align with file size")


def read_binary_manifest_version(data: bytes) -> tuple[int, str]:
    """Read versionCode/versionName from ADT's compiled Android manifest."""
    if len(data) < 8 or _read_u16(data, 0) != 0x0003:
        raise ValueError("input is not an Android binary XML document")
    if _read_u32(data, 4) != len(data):
        raise ValueError("AXML document size does not match its header")
    strings, pool_end = _decode_string_pool(data)
    found: dict[str, int | str] = {}
    for offset, chunk_type, _, chunk_size in _iter_axml_chunks(data, pool_end):
        if chunk_type != _AXML_START_ELEMENT or chunk_size < 36:
            continue
        element_index = _read_u32(data, offset + 20)
        if element_index >= len(strings) or strings[element_index] != "manifest":
            continue
        start, stride, count = struct.unpack_from("<HHH", data, offset + 24)
        for index in range(count):
            attr_offset = offset + 16 + start + index * stride
            key_index = _read_u32(data, attr_offset + 4)
            if key_index >= len(strings):
                raise ValueError("invalid manifest attribute key")
            key = strings[key_index]
            value_type = data[attr_offset + 15]
            value_data = _read_u32(data, attr_offset + 16)
            if key == "versionCode" and value_type in (0x10, 0x11):
                found[key] = value_data
            elif key == "versionName" and value_type == 0x03 and value_data < len(strings):
                found[key] = strings[value_data]
    if set(found) != {"versionCode", "versionName"}:
        raise ValueError("manifest version properties were not found")
    return int(found["versionCode"]), str(found["versionName"])


def read_binary_manifest_cleartext(data: bytes) -> bool:
    """Read the compiled application usesCleartextTraffic flag from AXML."""
    if len(data) < 8 or _read_u16(data, 0) != 0x0003:
        raise ValueError("input is not an Android binary XML document")
    if _read_u32(data, 4) != len(data):
        raise ValueError("AXML document size does not match its header")
    strings, pool_end = _decode_string_pool(data)
    for offset, chunk_type, _, chunk_size in _iter_axml_chunks(data, pool_end):
        if chunk_type != _AXML_START_ELEMENT or chunk_size < 36:
            continue
        element_index = _read_u32(data, offset + 20)
        if element_index >= len(strings) or strings[element_index] != "application":
            continue
        start, stride, count = struct.unpack_from("<HHH", data, offset + 24)
        for index in range(count):
            attr_offset = offset + 16 + start + index * stride
            key_index = _read_u32(data, attr_offset + 4)
            if key_index >= len(strings):
                raise ValueError("invalid application attribute key")
            if strings[key_index] != "usesCleartextTraffic":
                continue
            value_type = data[attr_offset + 15]
            value_data = _read_u32(data, attr_offset + 16)
            if value_type != 0x12:
                raise ValueError("usesCleartextTraffic is not compiled as a boolean")
            return value_data != 0
    raise ValueError("application usesCleartextTraffic property was not found")
