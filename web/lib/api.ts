import type {
  Folder,
  GetFoldersResponse,
  GetItemsResponse,
  Item,
} from '@/types/index'

function getApiUrl(): string {
  const url = process.env.NEXT_PUBLIC_API_URL
  if (!url) throw new Error('NEXT_PUBLIC_API_URL is not defined')
  return url
}

export async function getFolders(): Promise<Folder[]> {
  const response = await fetch(`${getApiUrl()}/folders`)
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

  const response = await fetch(
    `${getApiUrl()}/items?${searchParams.toString()}`
  )
  if (!response.ok) {
    throw new Error(`Failed to fetch items: ${response.statusText}`)
  }
  return (await response.json()) as GetItemsResponse
}

export async function updateItem(itemId: string, state: string): Promise<Item> {
  const response = await fetch(`${getApiUrl()}/items/${itemId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ state }),
  })
  if (!response.ok) {
    throw new Error(`Failed to update item: ${response.statusText}`)
  }
  return (await response.json()) as Item
}
