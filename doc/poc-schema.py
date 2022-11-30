from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.client import User
from diagrams.aws.database import Dynamodb
from diagrams.aws.network import APIGateway

with Diagram("API Gateway / DynamoDB direct integration POC", show=False, direction="LR"):
    user = User("User")

    with Cluster("AWS"):
        apiGateWay = APIGateway("API Gateway")
        dynamoDB = Dynamodb("DynamoDB")

    user >> Edge(label="POST /pets") >> apiGateWay
    user >> Edge(label="GET /pets/<id>") >> apiGateWay
    apiGateWay >> Edge(label="Direct integration") >> dynamoDB