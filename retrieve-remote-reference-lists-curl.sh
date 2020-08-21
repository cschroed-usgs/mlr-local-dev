#!/bin/bash
mkdir remote-references
curl -o ./remote-references/aquifer.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/aquifer.json
curl -o ./remote-references/county.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/county.json
curl -o ./remote-references/huc.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/huc.json
curl -o ./remote-references/land_net.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/land_net.json
curl -o ./remote-references/mcd.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/mcd.json
curl -o ./remote-references/national_aquifer.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/national_aquifer.json
curl -o ./remote-references/national_water_use.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/national_water_use.json
curl -o ./remote-references/reference_lists.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/reference_lists.json
curl -o ./remote-references/site_number_format.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/site_number_format.json
curl -o ./remote-references/state.json https://prod-owi-resources.s3-us-west-2.amazonaws.com/resources/Application/mlr/test/configuration/mlr-validator/remote-references/state.json