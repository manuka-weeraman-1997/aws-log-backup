const fs = require("fs");
const path = require("path");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const s3 = new S3Client({});
const LOG_DIR = "/mnt/logs";

exports.handler = async () => {
  const files = fs.readdirSync(LOG_DIR);

  for (const file of files) {
    const fullPath = path.join(LOG_DIR, file);
    const body = fs.readFileSync(fullPath);

    await s3.send(new PutObjectCommand({
      Bucket: process.env.S3_BUCKET,
      Key: `logs/${file}`,
      Body: body,
    }));

    // Only remove from staging once S3 has confirmed the write.
    fs.unlinkSync(fullPath);
  }

  return { synced: files.length };
};
