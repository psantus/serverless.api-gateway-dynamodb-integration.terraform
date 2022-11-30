resource "aws_api_gateway_model" "empty_model" {
  content_type = "application/json"
  name         = "EmptyModel"
  rest_api_id  = aws_api_gateway_rest_api.pets_api.id

  schema = <<EOF
{
	"$schema": "http://json-schema.org/draft-04/schema#",
	"title": "EmptyResponse",
	"type": "null"
}
EOF
}

resource "aws_api_gateway_model" "error_response_model" {
  content_type = "application/json"
  name         = "ErrorResponse"
  rest_api_id  = aws_api_gateway_rest_api.pets_api.id

  schema = <<EOF
{
	"$schema": "http://json-schema.org/draft-04/schema#",
	"title": "PostResponse",
	"type": "object",
	"properties": {
		"type": {
			"type": "string"
		},
        "message": {
			"type": "string"
		}
	}
}
EOF
}

resource "aws_api_gateway_model" "pets_post_request_model" {
  content_type = "application/json"
  name         = "PostRootObject"
  rest_api_id  = aws_api_gateway_rest_api.pets_api.id

  schema = <<EOF
{
	"$schema": "http://json-schema.org/draft-04/schema#",
	"title": "PostRootObject",
	"type": "object",
	"properties": {
		"datas": {
			"type": "array",
			"items": {
				"$ref": "https://apigateway.amazonaws.com/restapis/${aws_api_gateway_rest_api.pets_api.id}/models/${aws_api_gateway_model.pet.name}"
			}
		}
	}
}
EOF
}

resource "aws_api_gateway_model" "get_response_model" {
  content_type = "application/json"
  name         = "GetRootObject"
  rest_api_id  = aws_api_gateway_rest_api.pets_api.id

  schema = <<EOF
{
	"$schema": "http://json-schema.org/draft-04/schema#",
	"title": "GetRootObject",
	"type": "object",
	"properties": {
		"datas": {
			"type": "array",
			"items": {
				"type": "array",
                "minItems": 1,
                "maxItems": 25,
				"items": {
					"$ref": "https://apigateway.amazonaws.com/restapis/${aws_api_gateway_rest_api.pets_api.id}/models/${aws_api_gateway_model.pet.name}"
				}
			}
		}
	}
}
EOF
}

resource "aws_api_gateway_model" "pet" {
  content_type = "application/json"
  name         = "Pet"
  rest_api_id  = aws_api_gateway_rest_api.pets_api.id

  schema = <<EOF
{
	"$schema": "http://json-schema.org/draft-04/schema#",
	"title": "Trame",
	"type": "object",
	"properties": {
        "name": {
			"type": "string"
		},
		"owner": {
			"type": "string"
		},
        "race": {
			"type": "string"
		},
		"age": {
			"type": "number"
		},
		"gender": {
			"type": "string"
		}
	},
    "required": ["name", "owner"],
    "definitions": {
        "gender": { "enum": ["M", "F"] }
    }
}
EOF
}
