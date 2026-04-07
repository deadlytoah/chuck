'use client'

import { ITEM_STATES } from '@/types/index'

interface StateOverlayProps {
  currentState: string
  onSelect: (state: string) => void
}

export default function StateOverlay({
  currentState,
  onSelect,
}: StateOverlayProps) {
  return (
    <div
      className="overlay-open absolute inset-0 z-10 bg-black/60 flex flex-col items-center justify-evenly"
      onClick={(e) => e.stopPropagation()}
    >
      {ITEM_STATES.filter((state) => state !== currentState).map((state) => (
        <button
          key={state}
          onClick={() => onSelect(state)}
          className="min-h-[44px] w-full px-4 text-white font-semibold text-sm active:bg-white/20"
        >
          {state}
        </button>
      ))}
    </div>
  )
}
