locals {
  post_request_mapping = <<REQUESTMAPPING
{
  "RequestItems": {
    "${aws_dynamodb_table.pets.name}" : [
      #foreach($item in $input.path('$'))
      {
        "PutRequest" : {
          "Item":{
            "owner" : { "S" : "$item.owner"},
            "name": { "S" : "$item.name"}
            #if($item.race),"race": { "S" : "$item.race"}#end
            #if($item.age),"age": { "N": "$item.age"}#end
            #if($item.gender),"gender":{ "S": "$item.gender"}#end
          }
        }
      }
      #if($foreach.hasNext),#end
      #end
    ]
  }
}
REQUESTMAPPING

  dynamodb_error_response_mapping = <<POSTRESPONSEMAPPING
{
  ## Pass-through DynamoDB error : https://docs.aws.amazon.com/fr_fr/amazondynamodb/latest/developerguide/Programming.Errors.html#Programming.Errors.Components
  "type": "$input.path('$.__type')",
  "message": "$input.path('$.message')"
}
POSTRESPONSEMAPPING

  #Owner being a reserver keyword in dynamo, we need to escape it below
  get_request_mapping = <<GETREQUESTMAPPING
{
  "TableName":"${aws_dynamodb_table.pets.name}",
  "KeyConditionExpression":"#petowner=:v1 #if($input.params('name')!= "")AND name=:v2#end",
  #if($input.params('race') != "" || $input.params('gender') != "" || $input.params('minAge') != "" || $input.params('maxAge') != "")
  "FilterExpression": "#if($input.params('race') != "")race=:v3#end #if($input.params('gender') != "")#if($input.params('race') != "")AND#end gender=:v4#end #if($input.params('minAge') != "")#if($input.params('race') != "" || $input.params('gender') != "")AND#end age>=:v5#end #if($input.params('maxAge') != "")#if($input.params('race') != "" || $input.params('gender') != "" || $input.params('minAge') != "")AND#end age<=:v6#end",
  #end
  "ExpressionAttributeNames" : {"#petowner": "owner"},
  "ExpressionAttributeValues":{
    ":v1":{"S":"$util.urlDecode($input.params('owner'))"}
    #if($input.params('name') != ""), ":v2":{"S":"$util.urlDecode($input.params('name'))"}#end
    #if($input.params('race') != ""), ":v3":{"S":"$util.urlDecode($input.params('race'))"}#end
    #if($input.params('gender') != ""), ":v4":{"S":"$util.urlDecode($input.params('gender'))"}#end
    #if($input.params('minAge') != ""), ":v5":{"N":"$util.urlDecode($input.params('minAge'))"}#end
    #if($input.params('maxAge') != ""), ":v6":{"N":"$util.urlDecode($input.params('maxAge'))"}#end
  }
}
GETREQUESTMAPPING

  get_response_mapping = <<GETRESPONSEMAPPING
#set($pets = $input.path('$').Items)
[
#foreach($pet in $pets)
    {
        "owner" : "$pet.owner.S",
        "name" : "$pet.name.S",
        "race" : "$pet.race.S",
        "age" : $pet.age.N,
        "gender" : "$pet.gender.S"
    }
#if($foreach.hasNext),#end
#end
]
GETRESPONSEMAPPING

}