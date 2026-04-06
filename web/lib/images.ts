function getS3Base(): string {
  const base = process.env.NEXT_PUBLIC_S3_BASE
  if (!base) throw new Error('NEXT_PUBLIC_S3_BASE is not defined')
  return base
}

export function thumbUrl(imageUrl: string): string {
  const thumbKey = imageUrl.replace(/\/full\//g, '/thumb/')
  return `${getS3Base()}${thumbKey}`
}

export function fullUrl(imageUrl: string): string {
  return `${getS3Base()}${imageUrl}`
}
