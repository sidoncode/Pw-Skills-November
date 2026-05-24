## policy example

```

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::rav-ram-bavan/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "223.233.69.81"
        }
      }
    }
  ]
}

```
