# wordpress-3tier-efs-s3

Wordpress within AWS VPC/3Tier/EFS/S3 implementation in Terraform

By default can be used for two workspaces. For example: `prod` (or `default`) and `dev`.

Workspace related variables **can** be included as: 

<pre><code>-var-file (prod|dev).tfvars</code></pre>

After deployment and Wordpress installation in its GUI, W3 Total Cache plugin 
**can** be enabled for EFS caching and static content offload to S3 bucket. It 
is already integrated into Wordpress in the time of deployment and recommended 
by Amazon for these purposes. Enable S3 CDN type on plugin's General Settings 
tab. Then on CDN tab enter connection parameters for S3.

S3 bucket parameters are in the output variables. As well as other useful 
system's data.

IAM user secret for S3 bucket access can be obtained by invoking:

<pre><code>terraform output -raw s3_iam_user_secret</code></pre>