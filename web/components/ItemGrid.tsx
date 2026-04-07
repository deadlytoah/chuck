'use client'

import type { Item } from '@/types/index'
import ItemCard from './ItemCard'

interface ItemGridProps {
  items: Item[]
  loading: boolean
  hasMore: boolean
  onLoadMore: () => void
}

export default function ItemGrid({
  items,
  loading,
  hasMore,
  onLoadMore,
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
      <div className="grid grid-cols-2 gap-2 px-2 flex-1">
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
