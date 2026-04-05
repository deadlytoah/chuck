const S3_BASE = process.env.NEXT_PUBLIC_S3_BASE

if (!S3_BASE) {
  throw new Error('NEXT_PUBLIC_S3_BASE is not defined')
}

export function thumbUrl(imageUrl: string): string {
  const thumbKey = imageUrl.replace(/\/full\//g, '/thumb/')
  return `${S3_BASE}${thumbKey}`
}

export function fullUrl(imageUrl: string): string {
  return `${S3_BASE}${imageUrl}`
}
