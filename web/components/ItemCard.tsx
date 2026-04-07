'use client'

import type { Item } from '@/types/index'
import { thumbUrl } from '@/lib/images'
import StateOverlay from './StateOverlay'

interface ItemCardProps {
  item: Item
  isOpen: boolean
  onOpen: () => void
  onClose: () => void
  onStateChange: (itemId: string, newState: string) => void
}

const stateColors: Record<string, { bg: string; text: string }> = {
  Chuck: { bg: 'bg-red-100', text: 'text-red-800' },
  Keep: { bg: 'bg-green-100', text: 'text-green-800' },
  Sell: { bg: 'bg-blue-100', text: 'text-blue-800' },
  Undecided: { bg: 'bg-yellow-100', text: 'text-yellow-800' },
  Unanswered: { bg: 'bg-purple-100', text: 'text-purple-800' },
}

export default function ItemCard({
  item,
  isOpen,
  onOpen,
  onClose,
  onStateChange,
}: ItemCardProps) {
  const colors = stateColors[item.state] || {
    bg: 'bg-gray-100',
    text: 'text-gray-800',
  }

  const handleStateSelect = (newState: string) => {
    onClose()
    onStateChange(item.itemId, newState)
  }

  return (
    <div className="flex flex-col">
      <div
        className="aspect-square overflow-hidden bg-gray-200 rounded relative"
        onClick={(e) => {
          if (!isOpen) {
            onOpen()
            e.stopPropagation()
          }
        }}
      >
        <img
          src={thumbUrl(item.imageUrl)}
          loading="lazy"
          alt=""
          className="w-full h-full object-cover"
        />
        {isOpen && (
          <StateOverlay
            currentState={item.state}
            onSelect={handleStateSelect}
          />
        )}
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
