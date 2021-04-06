# generator
This is a general purpose OpenAPI code generator. It is currently used to completely generate the http code in the Java SDK, and generate some of the http code in our golang SDK.

# Usage
We currently have two http endpoints. One for algod and one for indexer, so in most cases this tool would be run once with each OpenAPI spec.

### Build as a self-executing jar:
```
~$ mvn package -DskipTests
~$ java -jar target/generator-*-jar-with-dependencies.jar -h
```

You'll see that there are a number of subcommands:
* **java** - the original Java SDK generator.
* **responses** - generate randomized testfiles for SDK unit tests.
* **template** - a generator that uses velocity templates rather than Java code to configure the code generation.

# Templates

The template subcommand is using [Apache Velocity](https://velocity.apache.org/) as the underlying template engine. Things like variables, loops, and statements are all supported. So business logic can technically be implemented in the template if it's actually necessary.

### template files
There are three phases: **client**, **query**, and **model**. Each phase must provide two templates, one for the file generation and one to specify the filename to be used. If all results should go to the same file. For **query** and **model** generation the template will be executed once for each **query** / **model**. If you want to put everything in one file return the same filename twice in a row and the processing will exit early.

| phase | filename | purpose |
| ----- | -------- | ------- |
| client | client.vm          | Client class with functions to call each query. |
| client | client_filename.vm | File to write to the client output directory. |
| query  | query.vm           | Template to use for generating query files. |
| query  | query_filename.vm  | File to write to the query output directory. |
| model  | model.vm           | Template to use for generating model files. |
| model  | model_filename.vm  | File to write to the model output directory. |

### output directories
The template command will only run the templates which have an output directory is provided. So if you just want to regenerate models, only use the **-m** option.
```
  -c, --clientOutputDir
    Directory to write client file(s).
  -m, --modelsOutputDir
    Directory to write model file(s).
  -q, --queryOutputDir
    Directory to write query file(s).
```

### property files
The template subcommand accepts a **--propertyFiles** option. It can be provided multiple times, or as a comma separated list of files. Property files will be processed and bound to a velocity variable available to templates.

### template variables

For details on a type you can put it directly into your template. It will be serialized along with its fields for your reference. Here is a high level description of what is available:

| template | variable | type | purpose |
| -------- | -------- | ---- |------- |
| all      | str      | `StringHelpers.java` | Some string utilities are available. See `StringHelpers.java` for details. There are simple things like `$str.capitalize("someData")` -> `SomeData`, and also some more complex helpers like `$str.formatDoc($query.doc, "// ")` which will split the document at the word boundary nearest to 80 characters without going over, and add a prefix to each new line. |
| all      | order    | `OrderHelpers.java`  | Some ordering utilities available. See `OrderHelpers.java` for details. An example utility function is `$order.propertiesWithOrdering($props, $preferred_order)`, where `$props` is a list of properties and `$preferred_order` is a string list to use when ordering the properties list. |
| all      | propFile | `Properties` | The contents of all property files are available with this variable. For example if `package=com.algorand.v2.algod` is in the property file, the template may use `${propFile.package}`.
| all      | models   | `HashMap<StructDef, List<TypeDef>>` | A list of all models. |
| all      | queries  | `List<QueryDef>` | A list of all queries. |
| query    | q        | `QueryDef` | The current query definition. |
| model    | def      | `StructDef` | The current model definition if multiple files are being generated. |
| model    | props    | `List<TypeDef>` | A list of properties for the current model. |

### example usage

In the following example we are careful to generate the algod code first, because the algod models are a strict subset of the indexer models. For that reason we are able to reuse some overlapping models from indexer in algod.
```
~$ java -jar generator*jar template
        -s algod.oas2.json
        -t go_templates
        -c algodClient
        -m allModels
        -q algodQueries
        -p common_config.properties,algod_config.properties
~$ java -jar generator*jar template
        -s indexer.oas2.json
        -t go_templates
        -c indexerClient
        -m allModels
        -q indexerQueries
        -p common_config.properties,indexer_config.properties
```

# Test Template

There is a test template that gives you some basic usage in the **test_templates** directory.

You can generate the test code in the **output** directory with the following commands:
```
~$ mkdir output
~$ java -jar target/generator-*-jar-with-dependencies.jar \
    template \
    -s /path/to/a/spec/file/indexer.oas2.json \
    -t test_templates/ \
    -m output \
    -q output \
    -c output \
    -p test_templates/my.properties
```

# Golang Template

The go templates are in the **go_templates** directory.

The go http API is only partially generated. The hand written parts were not totally consistent with the spec and that makes it difficult to regenerate them. Regardless, an attempt has been made. In the templates there are some macros which map "generated" values to the hand written ones. For example the query types have this mapping:
```
#macro ( queryType )
#if ( ${str.capitalize($q.name)} == "SearchForAccounts" )
SearchAccounts## The hand written client doesn't quite match the spec...
#elseif ( ${str.capitalize($q.name)} == "GetStatus" )
Status##
#elseif ( ${str.capitalize($q.name)} == "GetPendingTransactionsByAddress" )
PendingTransactionInformationByAddress##
#elseif ( ${str.capitalize($q.name)} == "GetPendingTransactions" )
PendingTransactions##
#else
${str.capitalize($q.name)}##
#end
#end
```

Other mappings are more specific to the language, such as the OpenAPI type to SDK type:
```
#macro ( toQueryType $param )##
#if ( $param.algorandFormat == "RFC3339 String" )
string##
#elseif ( $param.type == "integer" )
uint64##
#elseif ( $param.type == "string" )
string##
#elseif ( $param.type == "boolean" )
bool##
#elseif( $param.type == "binary" )
string##
#else
UNHANDLED TYPE
- ref: $!param.refType
- type: $!param.type
- array type: $!param.arrayType
- algorand format: $!param.algorandFormat
- format: $!param.format
##$unknown.type ## force a template failure because $unknown.type does not exist.
#end
#end
```

Because of this, we are phasing in code generation gradually by skipping some types. The skipped types are specified in the property files:

**common_config.properties**
```
model_skip=AccountParticipation,AssetParams,RawBlockJson,etc,...
```

**algod_config.properties**
```
query_skip=Block,BlockRaw,SendRawTransaction,SuggestedParams,etc,...
```

**indexer_config.properties**
```
query_skip=LookupAssetByID,LookupAccountTransactions,SearchForAssets,LookupAssetBalances,LookupAssetTransactions,LookupBlock,LookupTransactions,SearchForTransactions
```

# Java Template
The Java templates are in the **java_templates** directory.

These are not used yet, they are the initial experiments for the template engine. Since the Java SDK has used code generation from the beginning, we should be able to fully migrate to the template engine eventually.

# Automation

## Preparing an external repository for automatic code generation

The automation will look in each passed GitHub repository for a `Dockerfile` in the `templates` directory, and will only run automatic code generation if one is present. For instructions on how to configure the `templates` directory, look at the [repository template directory example](./examples/repo_template_dir).

If you are trying to verify that automatic code generation works as intended, we recommend creating a testing branch from that repository and using the `--skip-pr` flag to avoid creating pull requests. If all goes according to plan, generated files should be available in the `clones/[repository name]` directory.

## Setting up the automatic generator

The automatic generator scripts depend on certain prerequisites that are listed in [automation/REQUIREMENTS.md](./automation/REQUIREMENTS.md). Once those conditions have been satisfied, automatically generating code for external repositories should be as easy as running the `automation/setup.sh` script, followed by the `automation/generate.sh` script for each individual, external repository, that requires generating.

For example, the following commands would generate and open PRs against the develop branches in the JS and Go SDKs.

```bash
$ ./automation/setup.sh
$ ./automation/generate.sh --repo "https://github.com/algorand/js-algorand-sdk" -b "develop"
$ ./automation/generate.sh --repo "https://github.com/algorand/go-algorand-sdk" -b "develop"
```
