"""Write plain game replies in AMF3 while PyAMF owns the remoting envelope."""
import datetime
import math
import struct

import pyamf
from pyamf import amf0, amf3, util


class _UseLibraryEncoder(Exception):
    pass


class ResponseContext(amf0.Context):
    def getAMF3Encoder(self, envelope_encoder):
        # A response body contains one root value. Remoting reference tables
        # start empty for each body, including batched and error replies.
        return _ResponseBody(envelope_encoder)


class _ResponseBody:
    def __init__(self, envelope_encoder):
        self.envelope_encoder = envelope_encoder
        self.buffer = bytearray()
        self.string_refs = {}
        self.object_refs = {}
        self.trait_refs = {}

    def writeElement(self, value):
        try:
            self._value(value)
        except _UseLibraryEncoder:
            # No partial bytes have reached the envelope. Preserve PyAMF's
            # handling of typed objects, ByteArrays and uncommon scalar types.
            amf3.Encoder(stream=self.envelope_encoder.stream,
                         timezone_offset=self.envelope_encoder.timezone_offset).writeElement(value)
            return
        self.envelope_encoder.stream.write(bytes(self.buffer))

    def _string(self, value):
        if not value:
            self.buffer.append(1)
            return
        ref = self.string_refs.get(value)
        if ref is None:
            encoded = value.encode("utf-8")
            self.string_refs[value] = amf3.encode_int(len(self.string_refs) << 1)
            self.buffer.extend(amf3.encode_int(len(encoded) << 1 | 1))
            self.buffer.extend(encoded)
        else:
            self.buffer.extend(ref)

    def _value(self, value):
        kind = type(value)
        out = self.buffer
        if kind is str:
            out.extend(amf3.TYPE_STRING)
            self._string(value)
        elif kind is int and amf3.MIN_29B_INT <= value <= amf3.MAX_29B_INT:
            out.extend(amf3.TYPE_INTEGER)
            out.extend(amf3.encode_int(value))
        elif kind in (float, int):
            if not math.isfinite(value):
                raise _UseLibraryEncoder
            out.extend(amf3.TYPE_NUMBER)
            out.extend(struct.pack(">d", value))
        elif kind is bool:
            out.extend(amf3.TYPE_BOOL_TRUE if value else amf3.TYPE_BOOL_FALSE)
        elif value is None:
            out.extend(amf3.TYPE_NULL)
        elif kind in (dict, pyamf.ASObject, list, tuple, datetime.datetime):
            self._object(value, kind)
        else:
            raise _UseLibraryEncoder

    def _object(self, value, kind):
        out = self.buffer
        mapping = kind is dict or kind is pyamf.ASObject
        is_date = kind is datetime.datetime
        if mapping:
            out.extend(amf3.TYPE_OBJECT)
        elif is_date:
            out.extend(amf3.TYPE_DATE)
        else:
            out.extend(amf3.TYPE_ARRAY)
        ref = self.object_refs.get(id(value))
        if ref is not None:
            out.extend(amf3.encode_int(ref << 1))
            return
        self.object_refs[id(value)] = len(self.object_refs)
        if mapping:
            trait = self.trait_refs.get(kind)
            if trait is None:
                # Dynamic anonymous object, followed by an empty class name.
                self.trait_refs[kind] = amf3.encode_int(len(self.trait_refs) << 2 | 1)
                out.extend(b"\x0b\x01")
            else:
                out.extend(trait)
            for key, item in value.items():
                if type(key) is int:
                    key = str(key)
                if type(key) is not str or not key:
                    raise _UseLibraryEncoder
                self._string(key)
                self._value(item)
            out.append(1)
        elif is_date:
            out.append(1)
            out.extend(struct.pack(">d", util.get_timestamp(value) * 1000.0))
        else:
            out.extend(amf3.encode_int(len(value) << 1 | 1))
            out.append(1)
            for item in value:
                self._value(item)
