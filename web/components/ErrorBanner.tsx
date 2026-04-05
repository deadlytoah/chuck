'use client'

interface ErrorBannerProps {
  message: string | null
  onRetry: () => void
}

export default function ErrorBanner({ message, onRetry }: ErrorBannerProps) {
  if (!message) {
    return null
  }

  return (
    <div className="bg-yellow-100 border-l-4 border-yellow-400 p-4 mb-4">
      <div className="flex justify-between items-center">
        <p className="text-yellow-700">{message}</p>
        <button
          onClick={onRetry}
          className="bg-yellow-400 hover:bg-yellow-500 text-yellow-800 px-3 py-1 rounded text-sm"
        >
          Retry
        </button>
      </div>
    </div>
  )
}
