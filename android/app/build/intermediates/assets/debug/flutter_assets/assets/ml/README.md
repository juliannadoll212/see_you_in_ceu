# TensorFlow Lite Models

This directory contains TensorFlow Lite models for image classification and object detection.

## Required Files

You need to download the following files and place them in this directory:

1. **MobileNet Model for Image Classification**:
   - Download [mobilenet_v1_1.0_224_quant.tflite](https://storage.googleapis.com/download.tensorflow.org/models/tflite/mobilenet_v1_1.0_224_quant_and_labels.zip)
   - Extract the zip file and place the `.tflite` file in this directory

## Usage

The Flutter app will load these models at runtime for object detection in the camera preview. 