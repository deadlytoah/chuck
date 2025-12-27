package main

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
)

var s3Client *s3.Client
var presignClient *s3.PresignClient

func initS3Client(ctx context.Context) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return err
	}
	s3Client = s3.NewFromConfig(cfg)
	presignClient = s3.NewPresignClient(s3Client)
	return nil
}

// generatePresignedURLs generates presigned URLs for thumbnail and full image
func generatePresignedURLs(ctx context.Context) (thumbURL, fullURL, imageKey string, err error) {
	if presignClient == nil {
		if err := initS3Client(ctx); err != nil {
			return "", "", "", err
		}
	}

	// Generate unique ID for this image
	id := uuid.New().String()

	// S3 keys
	thumbKey := fmt.Sprintf("images/%s/thumb.jpg", id)
	fullKey := fmt.Sprintf("images/%s/full.jpg", id)

	// Generate presigned URLs with 5 minute expiry
	thumbReq, err := presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(thumbKey),
		ContentType: aws.String("image/jpeg"),
	}, s3.WithPresignExpires(5*time.Minute))
	if err != nil {
		return "", "", "", err
	}

	fullReq, err := presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(fullKey),
		ContentType: aws.String("image/jpeg"),
	}, s3.WithPresignExpires(5*time.Minute))
	if err != nil {
		return "", "", "", err
	}

	return thumbReq.URL, fullReq.URL, fullKey, nil
}
