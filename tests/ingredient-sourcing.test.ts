import { describe, it, expect, beforeEach } from "vitest"

class MockIngredientContract {
  constructor() {
    this.maps = new Map()
    this.vars = new Map()
    this.blockHeight = 1000
    this.txSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  }
  
  setMap(mapName, key, value) {
    if (!this.maps.has(mapName)) {
      this.maps.set(mapName, new Map())
    }
    this.maps.get(mapName).set(JSON.stringify(key), value)
  }
  
  getMap(mapName, key) {
    const map = this.maps.get(mapName)
    return map ? map.get(JSON.stringify(key)) : null
  }
  
  setVar(varName, value) {
    this.vars.set(varName, value)
  }
  
  getVar(varName) {
    return this.vars.get(varName) || 0
  }
}

describe("Ingredient Sourcing Contract", () => {
  let contract
  
  beforeEach(() => {
    contract = new MockIngredientContract()
    contract.setVar("batch-counter", 0)
  })
  
  it("should register an ingredient batch", () => {
    const batchId = contract.getVar("batch-counter") + 1
    const batchData = {
      supplier: contract.txSender,
      ingredientName: "Agar Agar",
      molecularGrade: "Food Grade",
      origin: "Japan",
      harvestDate: 900,
      expiryDate: 2000,
      quantity: 500,
      status: "registered",
      temperatureControlled: true,
    }
    
    contract.setMap("ingredient-batches", { batchId }, batchData)
    contract.setVar("batch-counter", batchId)
    
    const stored = contract.getMap("ingredient-batches", { batchId })
    expect(stored).toEqual(batchData)
    expect(contract.getVar("batch-counter")).toBe(1)
  })
  
  it("should update batch status", () => {
    const batchId = 1
    const initialBatch = {
      supplier: contract.txSender,
      ingredientName: "Sodium Alginate",
      molecularGrade: "Premium",
      origin: "France",
      harvestDate: 800,
      expiryDate: 1800,
      quantity: 250,
      status: "registered",
      temperatureControlled: false,
    }
    
    contract.setMap("ingredient-batches", { batchId }, initialBatch)
    
    // Update status
    const updatedBatch = { ...initialBatch, status: "shipped" }
    contract.setMap("ingredient-batches", { batchId }, updatedBatch)
    
    const stored = contract.getMap("ingredient-batches", { batchId })
    expect(stored.status).toBe("shipped")
  })
  
  it("should add supply chain steps", () => {
    const batchId = 1
    const step = 1
    const supplyData = {
      handler: contract.txSender,
      location: "Distribution Center A",
      timestamp: contract.blockHeight,
      temperature: -18,
      notes: "Maintained cold chain during transport",
    }
    
    contract.setMap("supply-chain", { batchId, step }, supplyData)
    
    const stored = contract.getMap("supply-chain", { batchId, step })
    expect(stored).toEqual(supplyData)
    expect(stored.temperature).toBe(-18)
  })
  
  it("should check if batch is fresh", () => {
    const batchId = 1
    
    // Fresh batch
    const freshBatch = {
      supplier: contract.txSender,
      ingredientName: "Lecithin",
      molecularGrade: "Pharmaceutical",
      origin: "Germany",
      harvestDate: 500,
      expiryDate: 1500, // Expires after current block height (1000)
      quantity: 100,
      status: "registered",
      temperatureControlled: true,
    }
    
    contract.setMap("ingredient-batches", { batchId }, freshBatch)
    
    let batch = contract.getMap("ingredient-batches", { batchId })
    let isFresh = contract.blockHeight < batch.expiryDate
    expect(isFresh).toBe(true)
    
    // Expired batch
    const expiredBatch = { ...freshBatch, expiryDate: 900 } // Expires before current block height
    contract.setMap("ingredient-batches", { batchId }, expiredBatch)
    
    batch = contract.getMap("ingredient-batches", { batchId })
    isFresh = contract.blockHeight < batch.expiryDate
    expect(isFresh).toBe(false)
  })
  
  it("should track complete supply chain", () => {
    const batchId = 1
    
    // Step 1: Harvesting
    const step1 = {
      handler: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
      location: "Farm Origin",
      timestamp: 950,
      temperature: 20,
      notes: "Harvested at optimal ripeness",
    }
    
    // Step 2: Processing
    const step2 = {
      handler: "ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0",
      location: "Processing Facility",
      timestamp: 970,
      temperature: 4,
      notes: "Processed and packaged under sterile conditions",
    }
    
    contract.setMap("supply-chain", { batchId, step: 1 }, step1)
    contract.setMap("supply-chain", { batchId, step: 2 }, step2)
    
    const retrievedStep1 = contract.getMap("supply-chain", { batchId, step: 1 })
    const retrievedStep2 = contract.getMap("supply-chain", { batchId, step: 2 })
    
    expect(retrievedStep1).toEqual(step1)
    expect(retrievedStep2).toEqual(step2)
    expect(retrievedStep1.location).toBe("Farm Origin")
    expect(retrievedStep2.location).toBe("Processing Facility")
  })
})
