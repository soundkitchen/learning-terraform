# Learning Terraform

あくまでも自分用の調査・勉強したことの備忘録。
実行する場合は `terraform.sample.tfvars` を `terraform.tfvars` にリネームして適当な値を設定してもらえれば動くはず。
AWS 関連のものは実行するためには環境変数 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` をそれぞれ設定しておく必要がある。

* [S3 で静的ウェブサイト立てる](/aws-s3-static-website)
  * [独自ドメインで立てる](/aws-s3-static-website-with-alternative-domain)
* [ACM で証明書を発行する](/aws-certificate-manager)
