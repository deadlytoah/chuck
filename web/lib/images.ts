function getBase(): string {
  const base = process.env.NEXT_PUBLIC_S3_BASE
  if (!base) throw new Error('NEXT_PUBLIC_S3_BASE is not defined')
  return base.replace(/\/$/, '')
}

export function thumbUrl(imageUrl: string): string {
  return `${getBase()}/${imageUrl.replace(/\/full\.jpg$/, '/thumb.jpg')}`
}

export function fullUrl(imageUrl: string): string {
  return `${getBase()}/${imageUrl}`
}
