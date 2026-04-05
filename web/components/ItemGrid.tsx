'use client'

import type { Item } from '@/types/index'
import ItemCard from './ItemCard'

interface ItemGridProps {
  items: Item[]
  loading: boolean
  hasMore: boolean
  onLoadMore: () => void
  onRefresh: () => void
}

export default function ItemGrid({
  items,
  loading,
  hasMore,
  onLoadMore,
  onRefresh,
}: ItemGridProps) {
  if (loading && items.length === 0) {
    return (
      <div className="flex justify-center items-center py-8">
        <div className="text-gray-500">Loading...</div>
      </div>
    )
  }

  return (
    <div className="flex-1 flex flex-col">
      <div className="flex justify-between items-center mb-4 px-2">
        <h2 className="text-lg font-semibold">Items</h2>
        <button
          onClick={onRefresh}
          className="p-2 hover:bg-gray-100 rounded-full"
          aria-label="Refresh"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 px-2 flex-1">
        {items.map((item) => (
          <ItemCard key={item.itemId} item={item} />
        ))}
      </div>

      {items.length === 0 && !loading && (
        <div className="flex justify-center items-center py-8 text-gray-500">
          No items found
        </div>
      )}

      {hasMore && (
        <div className="flex justify-center mt-4 mb-4">
          <button
            onClick={onLoadMore}
            disabled={loading}
            className="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white px-4 py-2 rounded"
          >
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}
    </div>
  )
}
