import datetime
import unittest

import pyamf
from pyamf import remoting

from amf_response import ResponseContext


class ResponseEncodingTests(unittest.TestCase):
    def assert_wire_equal(self, values):
        envelope = remoting.Envelope(amfVersion=3)
        for index, value in enumerate(values):
            envelope[str(index)] = remoting.Response(value)
        expected = remoting.encode(envelope, strict=True).getvalue()
        actual = remoting.encode(envelope, strict=True, context=ResponseContext()).getvalue()
        self.assertEqual(actual, expected)

    def test_scalars_shared_objects_and_batch_references(self):
        stamp = datetime.datetime(1968, 3, 2, 11, 4, 8, 123456)
        row = {1: "中文", "": None}
        values = [True, False, "", None, -0.0, .25, -2**28, 2**28-1, -2**28-1,
                  2**28, 127, 128, 16384, 2097152, stamp, stamp, "中文", "中文"]
        node = {"scalars": values, "again": values, "object": pyamf.ASObject(num=1)}
        node["cycle"] = node
        self.assert_wire_equal([node, [node, (1, 2)], row])

    def test_typed_and_nonfinite_values_keep_library_encoding(self):
        from pyamf.amf3 import ByteArray
        for tail in (ByteArray(b"test"), pyamf.Undefined, float("nan"), float("inf")):
            with self.subTest(tail=type(tail).__name__):
                self.assert_wire_equal([{"prefix": [{"a": 1}], "tail": tail}, {"a": 1}])
