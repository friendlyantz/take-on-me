import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-compressor"
export default class extends Controller {
  static targets = ["input", "status", "originalSize", "compressedSize"]
  static values = {
    maxSize: { type: Number, default: 1 }, // Max size in MB
    quality: { type: Number, default: 0.8 }, // JPEG quality (0-1)
    maxWidth: { type: Number, default: 800 },
    maxHeight: { type: Number, default: 800 }
  }

  connect() {
    console.log("Image compressor connected")
  }

  async compress(event) {
    const input = event.target
    const files = Array.from(input.files)
    
    if (files.length === 0) return

    // Show status
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Processing image..."
      this.statusTarget.classList.remove("hidden")
    }

    try {
      const compressedFiles = await Promise.all(
        files.map(file => this.compressFile(file))
      )

      // Create a new DataTransfer object to set the compressed files
      const dataTransfer = new DataTransfer()
      compressedFiles.forEach(file => dataTransfer.items.add(file))
      input.files = dataTransfer.files

      // Update status
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Image is ready to upload!"
        this.statusTarget.classList.add("alert-success")
        setTimeout(() => {
          this.statusTarget.classList.add("hidden")
          this.statusTarget.classList.remove("alert-success")
        }, 9000)
      }
    } catch (error) {
      console.error("Compression error:", error)
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = `Error: ${error.message}`
        this.statusTarget.classList.add("alert-error")
      }
    }
  }

  async compressFile(file) {
    // If not an image, return as-is
    if (!file.type.startsWith('image/')) {
      return file
    }

    const originalSize = file.size
    if (this.hasOriginalSizeTarget) {
      this.originalSizeTarget.textContent = this.formatBytes(originalSize)
    }

    // If file is already small enough, return as-is
    const maxBytes = this.maxSizeValue * 1024 * 1024
    if (originalSize <= maxBytes) {
      console.log(`File ${file.name} is already under ${this.maxSizeValue}MB`)
      if (this.hasCompressedSizeTarget) {
        this.compressedSizeTarget.textContent = this.formatBytes(originalSize)
      }
      return file
    }

    try {
      // Load the image
      const image = await this.loadImage(file)
      
      // Calculate new dimensions while maintaining aspect ratio
      let { width, height } = this.calculateDimensions(
        image.width,
        image.height,
        this.maxWidthValue,
        this.maxHeightValue
      )

      // Create canvas and compress
      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      
      const ctx = canvas.getContext('2d')
      ctx.drawImage(image, 0, 0, width, height)

      // Try different quality levels if needed
      let quality = this.qualityValue
      let blob = await this.canvasToBlob(canvas, file.type, quality)

      // If still too large, reduce quality further
      while (blob.size > maxBytes && quality > 0.1) {
        quality -= 0.1
        blob = await this.canvasToBlob(canvas, file.type, quality)
      }

      // If still too large, reduce dimensions
      if (blob.size > maxBytes) {
        const scale = Math.sqrt(maxBytes / blob.size) * 0.9
        width = Math.floor(width * scale)
        height = Math.floor(height * scale)
        
        canvas.width = width
        canvas.height = height
        ctx.drawImage(image, 0, 0, width, height)
        
        blob = await this.canvasToBlob(canvas, file.type, 0.8)
      }

      const compressedSize = blob.size
      if (this.hasCompressedSizeTarget) {
        this.compressedSizeTarget.textContent = this.formatBytes(compressedSize)
      }

      console.log(`Compressed ${file.name} from ${this.formatBytes(originalSize)} to ${this.formatBytes(compressedSize)}`)

      // Create a new File object from the blob
      return new File([blob], file.name, {
        type: blob.type,
        lastModified: Date.now()
      })
    } catch (error) {
      console.error(`Failed to compress ${file.name}:`, error)
      // Return original file if compression fails
      return file
    }
  }

  loadImage(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = new Image()
        img.onload = () => resolve(img)
        img.onerror = reject
        img.src = e.target.result
      }
      reader.onerror = reject
      reader.readAsDataURL(file)
    })
  }

  calculateDimensions(width, height, maxWidth, maxHeight) {
    if (width <= maxWidth && height <= maxHeight) {
      return { width, height }
    }

    const ratio = Math.min(maxWidth / width, maxHeight / height)
    return {
      width: Math.floor(width * ratio),
      height: Math.floor(height * ratio)
    }
  }

  canvasToBlob(canvas, type, quality) {
    return new Promise((resolve) => {
      canvas.toBlob(resolve, type, quality)
    })
  }

  formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
}
