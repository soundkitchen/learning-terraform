# アカウントレベルの S3 のパブリックアクセス制限を設定する

## やること

* アカウントレベルの S3 のパブリックアクセス制限を設定する


アカウントによっては最初から設定されているものもあるっぽい？ので、その場合は `terraform import` を使って既存の設定を読み込む必要がある。その際に AWS のアカウント ID が必要になる。

```sh
$ terraform import aws_s3_account_public_access_block.main <ACCOUNT_ID>
```
