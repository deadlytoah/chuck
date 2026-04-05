'use client'

import { useEffect, useState } from 'react'
import type { Folder, Item, GetItemsResponse } from '@/types/index'
import { getFolders, getItems } from '@/lib/api'
import { getStoredFolderId, setStoredFolderId } from '@/lib/storage'
import ErrorBanner from '@/components/ErrorBanner'
import ItemGrid from '@/components/ItemGrid'
import FolderSelector from '@/components/FolderSelector'

export default function Home() {
  const [folders, setFolders] = useState<Folder[]>([])
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null)
  const [items, setItems] = useState<Item[]>([])
  const [nextToken, setNextToken] = useState<string | undefined>()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Initial load: get folders and resolve initial folder
  useEffect(() => {
    const initializeFolders = async () => {
      try {
        setLoading(true)
        const fetchedFolders = await getFolders()
        setFolders(fetchedFolders)

        // Resolve initial folder
        let initialFolderId: string | null = null

        // Try stored folderId first
        const storedId = getStoredFolderId()
        if (storedId && fetchedFolders.some((f) => f.folderId === storedId)) {
          initialFolderId = storedId
        }

        // Try "Inbox" folder
        if (!initialFolderId) {
          const inboxFolder = fetchedFolders.find((f) => f.name === 'Inbox')
          if (inboxFolder) {
            initialFolderId = inboxFolder.folderId
          }
        }

        // Try first alphabetically
        if (!initialFolderId && fetchedFolders.length > 0) {
          const sorted = [...fetchedFolders].sort((a, b) =>
            a.name.localeCompare(b.name)
          )
          initialFolderId = sorted[0].folderId
        }

        if (initialFolderId) {
          setSelectedFolderId(initialFolderId)
          setStoredFolderId(initialFolderId)
          await fetchItemsForFolder(initialFolderId)
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load folders')
      } finally {
        setLoading(false)
      }
    }

    initializeFolders()
  }, [])

  const fetchItemsForFolder = async (
    folderId: string,
    nextTokenValue?: string
  ) => {
    try {
      setError(null)
      const response = (await getItems({
        folderId,
        nextToken: nextTokenValue,
        sort: 'createdAt',
      })) as GetItemsResponse

      if (nextTokenValue) {
        // Append items
        setItems((prev) => [...prev, ...response.data])
      } else {
        // Replace items
        setItems(response.data)
      }

      setNextToken(response.pagination?.nextToken)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load items')
    }
  }

  const handleFolderChange = async (folderId: string) => {
    setSelectedFolderId(folderId)
    setItems([])
    setNextToken(undefined)
    setStoredFolderId(folderId)
    await fetchItemsForFolder(folderId)
  }

  const handleLoadMore = async () => {
    if (selectedFolderId && nextToken) {
      await fetchItemsForFolder(selectedFolderId, nextToken)
    }
  }

  const handleRefresh = async () => {
    setItems([])
    setNextToken(undefined)
    setError(null)

    try {
      setLoading(true)
      const fetchedFolders = await getFolders()
      setFolders(fetchedFolders)

      if (selectedFolderId) {
        await fetchItemsForFolder(selectedFolderId)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to refresh')
    } finally {
      setLoading(false)
    }
  }

  const handleRetry = async () => {
    if (selectedFolderId) {
      await fetchItemsForFolder(selectedFolderId)
    } else {
      await handleRefresh()
    }
  }

  return (
    <main className="flex flex-1 flex-col">
      <FolderSelector
        folders={folders}
        selectedFolderId={selectedFolderId}
        onSelect={handleFolderChange}
      />

      <div className="flex-1 flex flex-col p-2 overflow-hidden">
        <ErrorBanner message={error} onRetry={handleRetry} />

        <ItemGrid
          items={items}
          loading={loading}
          hasMore={!!nextToken}
          onLoadMore={handleLoadMore}
          onRefresh={handleRefresh}
        />
      </div>
    </main>
  )
}
