EXAMPLE FOR GENERATING TRANSACTION MODEL:

java -jar generator-1.0.0-jar-with-dependencies.jar template -s ..\dotnet_templates\Transactions.json -t ..\dotnet_templates -m ..\output_txns -p "..\dotnet_templates\transactions_model_config.properties"

EXAMPLE FOR GENERATING ALGOD MODEL:
java -jar generator-1.0.0-jar-with-dependencies.jar template -s algod.oas2.json -t ..\dotnet_templates -m ..\output  -p "..\dotnet_templates\algod_model_config.properties"

FOR ALGOD COMMON CLIENT: 
java -jar generator-1.0.0-jar-with-dependencies.jar template -s algod.oas2.json -t ..\dotnet_templates -c ..\output_client  -p "..\dotnet_templates\algod_common_config.properties"

FOR ALGOD DEFAULT CLIENT: 
java -jar generator-1.0.0-jar-with-dependencies.jar template -s algod.oas2.json -t ..\dotnet_templates -c ..\output_client  -p "..\dotnet_templates\algod_default_config.properties"

