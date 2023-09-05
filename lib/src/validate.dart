import 'package:json_typedef_dart/src/errors.dart';
import 'package:json_typedef_dart/src/rfc339.dart';
import 'package:json_typedef_dart/src/schema.dart';
import 'package:json_typedef_dart/src/types.dart';

class ValidationError {
  List<String> instancePath;
  List<String> schemaPath;

  ValidationError({required this.instancePath, required this.schemaPath});

  Json toMap() {
    return <String, dynamic>{
      "instancePath": instancePath,
      "schemaPath": schemaPath
    };
  }
}

class ValidationState {
  List<ValidationError> errors = [];
  List<String> instanceTokens = [];
  List<List<String>> schemaTokens = [[]];
  Json root;

  int maxDepth;
  int maxErrors;

  bool Function(Json schema, dynamic instance, List<List<String>> schemaPath)?
      onMetadata;

  ValidationState(
      {required this.root,
      this.maxDepth = 0,
      this.maxErrors = 0,
      this.onMetadata});

  List<Map<String, dynamic>> errorList() {
    List<Map<String, dynamic>> err = [];

    for (ValidationError error in errors) {
      err.add(error.toMap());
    }
    return err;
  }

  void popSchemaToken() => schemaTokens.last.removeLast();

  void pushSchemaToken(String token) => schemaTokens.last.add(token);

  void popInstanceToken() => instanceTokens.removeLast();

  void pushInstanceToken(String token) => instanceTokens.add(token);

  void pushError() {
    errors.add(ValidationError(
      instancePath: [...instanceTokens],
      schemaPath: [...schemaTokens[schemaTokens.length - 1]],
    ));

    if (errors.length == maxErrors) {
      throw MaxErrorsReachedError();
    }
  }
}

/// validate performs JSON Typedef validation of an instance (or "input") against
/// a JSON Typedef schema, returning a standardized set of errors.
///
/// This function may throw [MaxDepthExceededError] if you have configured
/// a [maxDepth]. If you do not configure such a maxDepth,
/// then this function may cause a stack overflow. That's because of
/// circularly-defined schemas like this one:
///
/// ```json
/// {
///   "ref": "loop",
///   "definitions": {
///     "loop": { "ref": "loop" }
///   }
/// }
/// ```
///
/// If your schema is not circularly defined like this, then there is no risk for
/// validate to overflow the stack.
///
/// If you are only interested in a certain number of error messages, consider
/// using [maxErrors] to get better performance. For
/// instance, if all you care about is whether the input is OK or if it has
/// errors, you may want to set maxErrors to 1.
///
/// [schema] The schema to validate data against
/// [data] The "input" to validate
/// [maxDepth] How deep to recurse. Optional.
/// [onMetadata] Callback for metadata forms on a type form. Optional.
ValidationErrors validate(
    {required Json schema,
    required dynamic data,
    int maxDepth = 0,
    int maxErrors = 0,
    bool Function(Json schema, dynamic instance, List<List<String>> schemaPath)?
        onMetadata}) {
  ValidationState state = ValidationState(
      root: schema,
      maxDepth: maxDepth,
      maxErrors: maxErrors,
      onMetadata: onMetadata);
  try {
    validateWithState(state: state, schema: schema, instance: data);
  } catch (e) {
    if (e is MaxErrorsReachedError) {
    } else {
      rethrow;
    }
  }
  return state.errorList();
}

void validateWithState(
    {required ValidationState state,
    required Json schema,
    required dynamic instance,
    String? parentTag}) {
  if (hasNullable(schema) && instance == null) {
    return;
  }
  if (hasRef(schema)) {
    if (state.schemaTokens.length == state.maxDepth) {
      throw MaxDepthExceededError();
    }
    state.schemaTokens.add(["definitions", schema["ref"] as String]);
    validateWithState(
        state: state,
        schema: state.root["definitions"]![schema["ref"]] as Json,
        instance: instance);
    state.schemaTokens.removeLast();
  } else if (hasType(schema)) {
    state.pushSchemaToken("type");
    var errorCount = state.errors.length;
    switch (schema["type"]) {
      case 'boolean':
        if (instance is! bool) {
          state.pushError();
        }
        break;
      case "float32":
      case "float64":
        if (instance is! num) {
          state.pushError();
        }
        break;
      case "int8":
        validateInt(state, instance, -128, 127);
        break;
      case "uint8":
        validateInt(state, instance, 0, 255);
        break;
      case "int16":
        validateInt(state, instance, -32768, 32767);
        break;
      case "uint16":
        validateInt(state, instance, 0, 65535);
        break;
      case "int32":
        validateInt(state, instance, -2147483648, 2147483647);
        break;
      case "uint32":
        validateInt(state, instance, 0, 4294967295);
        break;
      case "string":
        if (instance is! String) {
          state.pushError();
        }
        break;
      case "timestamp":
        if (instance is! String) {
          state.pushError();
        } else {
          if (!isRFC3339(instance)) {
            state.pushError();
          }
        }
        break;
    }
    state.popSchemaToken();
    // only checking metadata if there is a type, and there were no errors in type
    if (hasMetadata(schema) &&
        errorCount == state.errors.length &&
        state.onMetadata != null) {
      state.pushSchemaToken("metadata");
      if (!state.onMetadata!(schema, instance, state.schemaTokens)) {
        state.pushError();
      }
      state.popSchemaToken();
    }
  } else if (hasEnum(schema)) {
    state.pushSchemaToken("enum");

    var enum_ = List<String>.from(schema["enum"] as List<dynamic>);
    if (instance is! String || !(enum_.contains(instance))) {
      state.pushError();
    }
    state.popSchemaToken();
  } else if (hasElements(schema)) {
    state.pushSchemaToken("elements");

    if (instance is List) {
      for (var i = 0; i < instance.length; i++) {
        state.pushInstanceToken(i.toString());
        validateWithState(
            state: state,
            schema: schema["elements"] as Json,
            instance: instance[i]);
        state.popInstanceToken();
      }
    } else {
      state.pushError();
    }

    state.popSchemaToken();
  } else if (isProperties(schema)) {
    if (instance is Json) {
      if (hasProperties(schema)) {
        state.pushSchemaToken("properties");
        for (var subSchema in (schema["properties"] as Json).entries) {
          state.pushSchemaToken(subSchema.key);
          if (instance.containsKey(subSchema.key)) {
            state.pushInstanceToken(subSchema.key);
            validateWithState(
                state: state,
                schema: subSchema.value as Json,
                instance: instance[subSchema.key]);
            state.popInstanceToken();
          } else {
            state.pushError();
          }
          state.popSchemaToken();
        }
        state.popSchemaToken();
      }

      if (hasOptionalProperties(schema)) {
        state.pushSchemaToken("optionalProperties");
        for (var subSchema in (schema["optionalProperties"] as Json).entries) {
          state.pushSchemaToken(subSchema.key);
          if (instance.containsKey(subSchema.key)) {
            state.pushInstanceToken(subSchema.key);
            validateWithState(
                state: state,
                schema: subSchema.value as Json,
                instance: instance[subSchema.key]);
            state.popInstanceToken();
          }
          state.popSchemaToken();
        }
        state.popSchemaToken();
      }

      if (!hasAdditionalProperties(schema) ||
          schema["additionalProperties"] != true) {
        for (var name in instance.keys) {
          bool inRequired = hasProperties(schema) &&
              (schema["properties"] as Json).containsKey(name);
          bool inOptional = hasOptionalProperties(schema) &&
              (schema["optionalProperties"] as Json).containsKey(name);

          if (!inRequired && !inOptional && name != parentTag) {
            state.pushInstanceToken(name);
            state.pushError();
            state.popInstanceToken();
          }
        }
      }
    } else {
      if (hasProperties(schema)) {
        state.pushSchemaToken("properties");
      } else {
        state.pushSchemaToken("optionalProperties");
      }

      state.pushError();
      state.popSchemaToken();
    }
  } else if (hasValues(schema)) {
    state.pushSchemaToken("values");

    // See comment in properties form on why this is the test we use for
    // checking for objects.
    if (instance is Json) {
      for (var subInstance in instance.entries) {
        state.pushInstanceToken(subInstance.key);
        validateWithState(
            state: state,
            schema: schema["values"] as Json,
            instance: subInstance.value);
        state.popInstanceToken();
      }
    } else {
      state.pushError();
    }

    state.popSchemaToken();
  } else if (hasDiscriminator(schema)) {
    // See comment in properties form on why this is the test we use for
    // checking for objects.
    if (instance is Json) {
      if (instance.containsKey(schema["discriminator"])) {
        if (instance[schema["discriminator"]] is String) {
          String tag = instance[schema["discriminator"]] as String;

          if ((schema["mapping"] as Json).containsKey(tag)) {
            state.pushSchemaToken("mapping");
            state.pushSchemaToken(tag);
            validateWithState(
                state: state,
                schema: schema["mapping"][tag] as Json,
                instance: instance,
                parentTag: schema["discriminator"] as String);
            state.popSchemaToken();
            state.popSchemaToken();
          } else {
            state.pushSchemaToken("mapping");
            state.pushInstanceToken(schema["discriminator"] as String);
            state.pushError();
            state.popInstanceToken();
            state.popSchemaToken();
          }
        } else {
          state.pushSchemaToken("discriminator");
          state.pushInstanceToken(schema["discriminator"].toString());
          state.pushError();
          state.popInstanceToken();
          state.popSchemaToken();
        }
      } else {
        state.pushSchemaToken("discriminator");
        state.pushError();
        state.popSchemaToken();
      }
    } else {
      state.pushSchemaToken("discriminator");
      state.pushError();
      state.popSchemaToken();
    }
  }
}

void validateInt(ValidationState state, dynamic instance, num min, num max) {
  if (instance is! num ||
      instance is! int ||
      instance < min ||
      instance > max) {
    state.pushError();
  }
}
