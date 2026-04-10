import type { Folder, Item } from '../../types/index'

export const folders: Folder[] = [
  {
    folderId: 'f1',
    name: 'Inbox',
    createdAt: '2024-01-01T00:00:00Z',
  },
  {
    folderId: 'f2',
    name: 'Archive',
    createdAt: '2024-01-02T00:00:00Z',
  },
]

export const itemsPage1: Item[] = [
  {
    itemId: 'item1',
    folderId: 'f1',
    imageUrl: 'https://example.com/img1.jpg',
    state: 'Undecided',
    archived: false,
    createdAt: '2024-01-10T00:00:00Z',
    updatedAt: '2024-01-10T00:00:00Z',
  },
  {
    itemId: 'item2',
    folderId: 'f1',
    imageUrl: 'https://example.com/img2.jpg',
    state: 'Undecided',
    archived: false,
    createdAt: '2024-01-11T00:00:00Z',
    updatedAt: '2024-01-11T00:00:00Z',
  },
]

export const itemsPage2: Item[] = [
  {
    itemId: 'item3',
    folderId: 'f1',
    imageUrl: 'https://example.com/img3.jpg',
    state: 'Keep',
    archived: false,
    createdAt: '2024-01-12T00:00:00Z',
    updatedAt: '2024-01-12T00:00:00Z',
  },
]

export const archiveItems: Item[] = [
  {
    itemId: 'item4',
    folderId: 'f2',
    imageUrl: 'https://example.com/img4.jpg',
    state: 'Chuck',
    archived: false,
    createdAt: '2024-01-13T00:00:00Z',
    updatedAt: '2024-01-13T00:00:00Z',
  },
]
