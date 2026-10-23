#!/bin/bash
yum update -y
amazon-linux-extras enable php8.2
yum clean metadata
yum install -y httpd php php-pdo php-mysqlnd jq aws-cli

systemctl start httpd
systemctl enable httpd

# Fetch the RDS-native secret from AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id "${SECRET_ID}" --region "${REGION}" --query SecretString --output text > /var/www/secret.json
chmod 644 /var/www/secret.json

# Safely inject the Terraform DB_HOST variable into a separate config file
cat <<EOF > /var/www/config.php
<?php
\$db_host = "${DB_HOST}";
?>
EOF

# Create index.php (Single quoted 'EOF' protects PHP variables from Bash)
cat <<'EOF' > /var/www/html/index.php
<?php
require '/var/www/config.php';
$secret_json = file_get_contents('/var/www/secret.json');
$creds = json_decode($secret_json, true);

$db_user = $creds['username'];
$db_pass = $creds['password'];
$db_name = 'appdb';

echo "<div style='font-family: Arial, sans-serif; text-align: center; margin-top: 50px;'>";
echo "<h1>🚀 AWS Infrastructure Deployment Successful!</h1>";

try {
    $conn = new PDO("mysql:host=" . $db_host . ";dbname=" . $db_name . ";charset=utf8mb4", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<h2 style='color: green;'>✅ Successfully connected to the private RDS MySQL database!</h2>";

    $token = file_get_contents("http://169.254.169.254/latest/api/token", false, stream_context_create([
        "http" => ["method" => "PUT", "header" => "X-aws-ec2-metadata-token-ttl-seconds: 21600"]
    ]));
    $instance_id = file_get_contents("http://169.254.169.254/latest/meta-data/instance-id", false, stream_context_create([
        "http" => ["method" => "GET", "header" => "X-aws-ec2-metadata-token: " . $token]
    ]));

    echo "<p>Served securely from EC2 Instance ID: <strong>" . $instance_id . "</strong></p>";
} catch(PDOException $e) {
    echo "<h2 style='color: red;'>❌ Database connection failed.</h2>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}
echo "</div>";
?>
EOF

chown apache:apache /var/www/html/index.php /var/www/config.php
chmod 644 /var/www/html/index.php /var/www/config.php