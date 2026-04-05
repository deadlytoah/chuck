import type {
  Folder,
  GetFoldersResponse,
  GetItemsResponse,
  Item,
} from '@/types/index'

const API_URL = process.env.NEXT_PUBLIC_API_URL

if (!API_URL) {
  throw new Error('NEXT_PUBLIC_API_URL is not defined')
}

export async function getFolders(): Promise<Folder[]> {
  const response = await fetch(`${API_URL}/folders`)
  if (!response.ok) {
    throw new Error(`Failed to fetch folders: ${response.statusText}`)
  }
  const json = (await response.json()) as GetFoldersResponse
  return json.data
}

export interface GetItemsParams {
  folderId: string
  nextToken?: string
  limit?: number
  sort?: string
}

export async function getItems(
  params: GetItemsParams
): Promise<GetItemsResponse> {
  const searchParams = new URLSearchParams()
  searchParams.append('folderId', params.folderId)
  if (params.nextToken) {
    searchParams.append('nextToken', params.nextToken)
  }
  if (params.limit) {
    searchParams.append('limit', String(params.limit))
  }
  if (params.sort) {
    searchParams.append('sort', params.sort)
  }

  const response = await fetch(`${API_URL}/items?${searchParams.toString()}`)
  if (!response.ok) {
    throw new Error(`Failed to fetch items: ${response.statusText}`)
  }
  return (await response.json()) as GetItemsResponse
}
