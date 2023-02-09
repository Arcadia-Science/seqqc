require("dotenv").config();
import axios from "axios";
import { ListObjectsCommand, ListObjectsCommandInput, _Object, S3Client } from "@aws-sdk/client-s3";
import { GetUserCommand, IAMClient } from "@aws-sdk/client-iam";
import { combineEmails, getOrCreateDirectoryName, startOfYesterdayUTC, startOfTodayUTC } from "./utils";

// AWS credential constants
const { AWS_BUCKET_NAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION } = process.env;

// AWS bucket constants
const { AWS_SOURCE_PREFIX } = process.env;

// Notification constants
const { NOTIFICATION_EMAIL } = process.env;

// Tower constants
const { TOWER_URL, TOWER_ACCESS_TOKEN } = process.env;

// AWS SDK clients
const S3_CLIENT = new S3Client({
    region: AWS_REGION,
    credentials: { accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY },
});

const IAM_CLIENT = new IAMClient({
    region: AWS_REGION,
    credentials: { accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY },
});

// Given an S3 object, select the CSV files that were last modified in the day before
function filterS3Objects(s3Objects: _Object[]) {
    return s3Objects
        .filter((s: _Object) => s.Key?.endsWith(".csv"))
        .filter((s: _Object) => new Date(s.LastModified) >= startOfYesterdayUTC())
        .filter((s: _Object) => new Date(s.LastModified) < startOfTodayUTC());
}

// Get all S3 objects given the input parameters
async function getS3Objects(listObjectsParams: ListObjectsCommandInput) {
    let objects: _Object[] = [];
    // Declare truncated as a flag that the while loop is based on.
    let truncated = true;
    // Declare a variable to which the key of the last element is assigned to in the response.
    let pageMarker;
    // while loop that runs until 'response.truncated' is false.
    while (truncated) {
        try {
            const response = await S3_CLIENT.send(new ListObjectsCommand(listObjectsParams));
            // return response; //For unit tests
            response.Contents.forEach((item: _Object) => {
                objects.push(item);
            });
            // Log the key of every item in the response to standard output.
            truncated = response.IsTruncated;
            // If truncated is true, assign the key of the last element in the response to the pageMarker variable.
            if (truncated) {
                pageMarker = response.Contents.slice(-1)[0].Key;
                // Assign the pageMarker value to bucketParams so that the next iteration starts from the new pageMarker.
                listObjectsParams.Marker = pageMarker;
            }
            // At end of the list, response.truncated is false, and the function exits the while loop.
        } catch (err) {
            console.log("Error", err);
            truncated = false;
        }
    }
    return objects;
}

// Get an S3 object fetch the owner email if available
// AWS IAM profiles don't support emails by default, but they can be added to
// profiles via "Tags"
async function getOwnerEmail(s3Object: _Object) {
    const iamUsername = s3Object?.Owner?.DisplayName;
    if (iamUsername) {
        const input = {
            UserName: iamUsername,
        };
        const response = await IAM_CLIENT.send(new GetUserCommand(input));
        return response?.User?.Tags?.find((obj) => obj?.Key?.toLowerCase() === "email")?.Value;
    }
    return null;
}

// Given the input file and a notification email, launch the pipeline on Tower
async function launchPipeline(csvKey: string, csvOwnerEmail: string) {
    const data = {
        params: {
            email: combineEmails([NOTIFICATION_EMAIL, csvOwnerEmail]),
            input: `s3://${AWS_BUCKET_NAME}/${csvKey}`,
            outdir: `s3://${AWS_BUCKET_NAME}/outdir/${getOrCreateDirectoryName(csvKey)}`,
        },
    };

    const client = axios.create({
        baseURL: TOWER_URL,
        headers: {
            Authorization: `Bearer ${TOWER_ACCESS_TOKEN}`,
            "Content-Type": "application/json",
        },
    });

    await client.post("", data);
}

export const runJob = async () => {
    const listObjectsParams: ListObjectsCommandInput = {
        Bucket: AWS_BUCKET_NAME,
        Prefix: AWS_SOURCE_PREFIX,
    };

    const objects = await getS3Objects(listObjectsParams);
    const csvObjects = filterS3Objects(objects);

    for (const csvObject of csvObjects) {
        const ownerEmail = await getOwnerEmail(csvObject);
        await launchPipeline(csvObject.Key, ownerEmail);
    }
    return true;
};

if (require.main === module) {
    runJob();
}
