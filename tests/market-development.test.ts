import { describe, it, expect, beforeEach } from "vitest"

describe("Market Development Contract", () => {
  let contractState
  
  beforeEach(() => {
    contractState = {
      listings: new Map(),
      transactions: new Map(),
      listingCounter: 0,
      transactionCounter: 0,
    }
  })
  
  describe("Market Listings", () => {
    it("should create listing successfully", () => {
      const listingData = {
        orgId: 1,
        productName: "Bio-based Solvent",
        description: "Environmentally friendly solvent",
        price: 100,
        quantity: 50,
        greenCertification: true,
        sustainabilityScore: 85,
      }
      
      const result = createListing(listingData, "ST1SELLER")
      
      expect(result.success).toBe(true)
      expect(result.listingId).toBe(1)
      expect(contractState.listings.has(1)).toBe(true)
    })
    
    it("should store listing data correctly", () => {
      const listingData = {
        orgId: 1,
        productName: "Green Catalyst",
        description: "Sustainable catalyst",
        price: 200,
        quantity: 25,
        greenCertification: true,
        sustainabilityScore: 90,
      }
      
      const result = createListing(listingData, "ST1SELLER")
      const stored = contractState.listings.get(result.listingId)
      
      expect(stored.seller).toBe("ST1SELLER")
      expect(stored.productName).toBe("Green Catalyst")
      expect(stored.active).toBe(true)
    })
  })
  
  describe("Product Purchases", () => {
    beforeEach(() => {
      createListing(
          {
            orgId: 1,
            productName: "Test Product",
            description: "Test description",
            price: 50,
            quantity: 100,
            greenCertification: true,
            sustainabilityScore: 80,
          },
          "ST1SELLER",
      )
    })
    
    it("should purchase product successfully", () => {
      const result = purchaseProduct(1, 10, "ST1BUYER")
      
      expect(result.success).toBe(true)
      expect(result.transactionId).toBe(1)
      
      const listing = contractState.listings.get(1)
      expect(listing.quantity).toBe(90)
    })
    
    it("should create transaction record", () => {
      const result = purchaseProduct(1, 15, "ST1BUYER")
      const transaction = contractState.transactions.get(result.transactionId)
      
      expect(transaction.buyer).toBe("ST1BUYER")
      expect(transaction.seller).toBe("ST1SELLER")
      expect(transaction.quantity).toBe(15)
      expect(transaction.totalPrice).toBe(750) // 15 * 50
      expect(transaction.status).toBe("completed")
    })
    
    it("should deactivate listing when quantity reaches zero", () => {
      purchaseProduct(1, 100, "ST1BUYER")
      
      const listing = contractState.listings.get(1)
      expect(listing.quantity).toBe(0)
      expect(listing.active).toBe(false)
    })
    
    it("should reject purchase with insufficient quantity", () => {
      const result = purchaseProduct(1, 150, "ST1BUYER")
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("insufficient-funds")
    })
  })
  
  describe("Listing Management", () => {
    beforeEach(() => {
      createListing(
          {
            orgId: 1,
            productName: "Management Test",
            description: "Test product",
            price: 75,
            quantity: 30,
            greenCertification: false,
            sustainabilityScore: 60,
          },
          "ST1SELLER",
      )
    })
    
    it("should update listing status by seller", () => {
      const result = updateListingStatus(1, false, "ST1SELLER")
      
      expect(result.success).toBe(true)
      expect(contractState.listings.get(1).active).toBe(false)
    })
    
    it("should reject status update from non-seller", () => {
      const result = updateListingStatus(1, false, "ST1UNAUTHORIZED")
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("unauthorized")
    })
  })
  
  // Mock functions
  function createListing(data, seller) {
    const listingId = ++contractState.listingCounter
    contractState.listings.set(listingId, {
      seller,
      ...data,
      listingDate: Date.now(),
      active: true,
    })
    return { success: true, listingId }
  }
  
  function purchaseProduct(listingId, quantity, buyer) {
    const listing = contractState.listings.get(listingId)
    if (!listing || !listing.active || listing.quantity < quantity) {
      return { success: false, error: "insufficient-funds" }
    }
    
    const transactionId = ++contractState.transactionCounter
    const totalPrice = listing.price * quantity
    
    // Update listing
    listing.quantity -= quantity
    listing.active = listing.quantity > 0
    
    // Create transaction
    contractState.transactions.set(transactionId, {
      buyer,
      seller: listing.seller,
      listingId,
      quantity,
      totalPrice,
      transactionDate: Date.now(),
      status: "completed",
    })
    
    return { success: true, transactionId }
  }
  
  function updateListingStatus(listingId, active, caller) {
    const listing = contractState.listings.get(listingId)
    if (!listing) {
      return { success: false, error: "not-found" }
    }
    
    if (listing.seller !== caller) {
      return { success: false, error: "unauthorized" }
    }
    
    listing.active = active
    return { success: true }
  }
})
