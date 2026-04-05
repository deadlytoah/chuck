export interface Folder {
  folderId: string
  name: string
  createdAt: string
}

export interface Item {
  itemId: string
  folderId: string
  imageUrl: string
  state: string
  notes?: string
  archived: boolean
  createdAt: string
  updatedAt: string
}

export interface GetItemsResponse {
  data: Item[]
  pagination?: {
    nextToken?: string
  }
  meta: {
    count: number
  }
}

export interface GetFoldersResponse {
  data: Folder[]
}
