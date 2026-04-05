'use client'

import type { Item } from '@/types/index'
import { thumbUrl } from '@/lib/images'

interface ItemCardProps {
  item: Item
}

const stateColors: Record<string, { bg: string; text: string }> = {
  Keep: { bg: 'bg-green-100', text: 'text-green-800' },
  Discard: { bg: 'bg-red-100', text: 'text-red-800' },
  Archive: { bg: 'bg-blue-100', text: 'text-blue-800' },
  Review: { bg: 'bg-yellow-100', text: 'text-yellow-800' },
}

export default function ItemCard({ item }: ItemCardProps) {
  const colors = stateColors[item.state] || {
    bg: 'bg-gray-100',
    text: 'text-gray-800',
  }

  return (
    <div className="flex flex-col">
      <div className="aspect-square overflow-hidden bg-gray-200 rounded">
        <img
          src={thumbUrl(item.imageUrl)}
          loading="lazy"
          alt=""
          className="w-full h-full object-cover"
        />
      </div>
      <div className="mt-2">
        <span
          className={`inline-block px-2 py-1 rounded-full text-xs font-semibold ${colors.bg} ${colors.text}`}
        >
          {item.state}
        </span>
      </div>
    </div>
  )
}
