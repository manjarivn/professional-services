import argparse
import datetime
import json

import googleapiclient.discovery
#test

def main(description, project_id, start_date, start_time, end_date, source_bucket,
         access_key_id, secret_access_key, sink_bucket):
    """Create a one-time transfer from Amazon S3 to Google Cloud Storage."""
    storagetransfer = googleapiclient.discovery.build('storagetransfer', 'v1')

    # Edit this template with desired parameters.
    transfer_job = {
        'description': description,
        'status': 'ENABLED',
        'projectId': project_id,
        'schedule': {
            'scheduleStartDate': {
                'day': start_date.day,
                'month': start_date.month,
                'year': start_date.year
            },
            'scheduleEndDate': {
                'day': end_date.day,
                'month': end_date.month,
                'year': end_date.year
            },
            'startTimeOfDay': {
                'hours': start_time.hour,
                'minutes': start_time.minute,
                'seconds': start_time.second
            }
        },
        'transferSpec': {
            'awsS3DataSource': {
                'bucketName': source_bucket,
                'awsAccessKey': {
                    'accessKeyId': access_key_id,
                    'secretAccessKey': secret_access_key
                }
            },
            'gcsDataSink': {
                'bucketName': sink_bucket
            }
        }
    }

    result = storagetransfer.transferJobs().create(body=transfer_job).execute()
    print('Returned transferJob: {}'.format(
        json.dumps(result, indent=4)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('description', help='Transfer description.')
    parser.add_argument('project_id', help='Your Google Cloud project ID.')
    parser.add_argument('start_date', help='Date YYYY/MM/DD.')
    parser.add_argument('start_time', help='UTC Time (24hr) HH:MM:SS.')
    parser.add_argument('end_date', help='Date YYYY/MM/DD.')
    parser.add_argument('source_bucket', help='AWS source bucket name.')
    parser.add_argument('access_key_id', help='Your AWS access key id.')
    parser.add_argument('secret_access_key', help='Your AWS secret access '
                        'key.')
    parser.add_argument('sink_bucket', help='GCS sink bucket name.')

    args = parser.parse_args()
    start_date = datetime.datetime.strptime(args.start_date, '%Y/%m/%d')
    start_time = datetime.datetime.strptime(args.start_time, '%H:%M:%S')
    end_date = datetime.datetime.strptime(args.end_date, '%Y/%m/%d')
    main(
        args.description,
        args.project_id,
        start_date,
        start_time,
        end_date,
        args.source_bucket,
        args.access_key_id,
        args.secret_access_key,
        args.sink_bucket)
