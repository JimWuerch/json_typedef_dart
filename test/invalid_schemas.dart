
import 'dart:convert';

Map<String,dynamic> InvalidSchemas = {
 // "null schema": null,
 // "boolean schema": true,
 // "integer schema": 1,
 // "float schema": 3.14,
 // "string schema": "foo",
//  "array schema": [],
  "illegal keyword": {
    "foo": 123
  },
  "nullable not boolean": {
    "nullable": 123
  },
  "definitions not object": {
    "definitions": 123
  },
  "definition not object": {
    "definitions": {
      "foo": 123
    }
  },
  "non-root definitions": {
    "definitions": {
      "foo": {
        "definitions": {
          "x": {}
        }
      }
    }
  },
  "ref not string": {
    "ref": 123
  },
  "ref but no definitions": {
    "ref": "foo"
  },
  "ref to non-existent definition": {
    "definitions": {},
    "ref": "foo"
  },
  "sub-schema ref to non-existent definition": {
    "definitions": {},
    "elements": {
      "ref": "foo"
    }
  },
  "type not string": {
    "type": 123
  },
  "type not valid string value": {
    "type": "foo"
  },
  "enum not array": {
    "enum": 123
  },
  "enum empty array": {
    "enum": []
  },
  "enum not array of strings": {
    "enum": [
      "foo",
      123,
      "baz"
    ]
  },
  "enum contains duplicates": {
    "enum": [
      "foo",
      "bar",
      "foo"
    ]
  },
  "elements not object": {
    "elements": 123
  },
  "elements not correct schema": {
    "elements": {
      "definitions": {
        "x": {}
      }
    }
  },
  "properties not object": {
    "properties": 123
  },
  "properties value not correct schema": {
    "properties": {
      "foo": {
        "definitions": {
          "x": {}
        }
      }
    }
  },
  "optionalProperties not object": {
    "optionalProperties": 123
  },
  "optionalProperties value not correct schema": {
    "optionalProperties": {
      "foo": {
        "definitions": {
          "x": {}
        }
      }
    }
  },
  "additionalProperties not boolean": {
    "properties": {},
    "additionalProperties": 123
  },
  "properties shares keys with optionalProperties": {
    "properties": {
      "foo": {},
      "bar": {}
    },
    "optionalProperties": {
      "foo": {},
      "baz": {}
    }
  },
  "values not object": {
    "values": 123
  },
  "values not correct schema": {
    "values": {
      "definitions": {
        "x": {}
      }
    }
  },
  "discriminator not string": {
    "discriminator": 123,
    "mapping": {}
  },
  "mapping not object": {
    "discriminator": "foo",
    "mapping": 123
  },
  "mapping value not correct schema": {
    "discriminator": "foo",
    "mapping": {
      "x": {
        "properties": {},
        "definitions": {
          "x": {}
        }
      }
    }
  },
  "mapping value not of properties form": {
    "discriminator": "foo",
    "mapping": {
      "x": {}
    }
  },
  "mapping value has nullable set to true": {
    "discriminator": "foo",
    "mapping": {
      "x": {
        "nullable": true,
        "properties": {
          "bar": {}
        }
      }
    }
  },
  "discriminator shares keys with mapping properties": {
    "discriminator": "foo",
    "mapping": {
      "x": {
        "properties": {
          "foo": {}
        }
      }
    }
  },
  "discriminator shares keys with mapping optionalProperties": {
    "discriminator": "foo",
    "mapping": {
      "x": {
        "optionalProperties": {
          "foo": {}
        }
      }
    }
  },
  "invalid form - ref and type": {
    "definitions": {
      "foo": {}
    },
    "ref": "foo",
    "type": "uint32"
  },
  "invalid form - type and enum": {
    "type": "uint32",
    "enum": [
      "foo"
    ]
  },
  "invalid form - enum and elements": {
    "enum": [
      "foo"
    ],
    "elements": {}
  },
  "invalid form - elements and properties": {
    "elements": {},
    "properties": {}
  },
  "invalid form - elements and optionalProperties": {
    "elements": {},
    "optionalProperties": {}
  },
  "invalid form - elements and additionalProperties": {
    "elements": {},
    "additionalProperties": true
  },
  "invalid form - additionalProperties alone": {
    "additionalProperties": true
  },
  "invalid form - properties and values": {
    "properties": {},
    "values": {}
  },
  "invalid form - values and discriminator": {
    "values": {},
    "discriminator": "foo",
    "mapping": {}
  },
  "invalid form - discriminator alone": {
    "discriminator": "foo"
  },
  "invalid form - mapping alone": {
    "mapping": {}
  }
};