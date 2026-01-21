import { defineConfig } from '@prisma/client'

export default defineConfig({
  directUrl: process.env.DATABASE_URL,
  datasourceUrl: process.env.DATABASE_URL,  // <-- per migrate
})
