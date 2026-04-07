function getS3Base(): string {
  const base = process.env.NEXT_PUBLIC_S3_BASE
  if (!base) throw new Error('NEXT_PUBLIC_S3_BASE is not defined')
  return base
}

function toKey(imageUrl: string): string {
  const base = getS3Base()
  return imageUrl.startsWith(base) ? imageUrl.slice(base.length) : imageUrl
}

export function thumbUrl(imageUrl: string): string {
  const key = toKey(imageUrl).replace(/\/full/g, '/thumb')
  return `${getS3Base()}${key}`
}

export function fullUrl(imageUrl: string): string {
  return `${getS3Base()}${toKey(imageUrl)}`
}
