# Lambda

This folder is where the AWS Lambda function code for this project will live.

## Purpose

Lambda functions in this project are expected to support event-driven pieces of the churn pipeline, such as triggering a Glue job when new data arrives, post-processing model output, or lightweight validation before data lands in the curated layer.

## Planned structure

Each Lambda function should get its own subfolder containing:

- The function's handler code.
- - A `requirements.txt` (or equivalent) listing any dependencies.
  - - A short `README.md` describing the function's trigger, inputs, outputs, and required IAM permissions.
   
    - ## Status
   
    - No function code has been added yet. This README is a placeholder to reserve the folder structure until the first Lambda function is implemented.
    - 
