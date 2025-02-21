export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      user_profiles: {
        Row: {
          id: string
          user_type: 'wholesaler' | 'retailer' | 'customer'
          first_name: string
          last_name: string
          email: string
          phone: string | null
          address: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          user_type: 'wholesaler' | 'retailer' | 'customer'
          first_name: string
          last_name: string
          email: string
          phone?: string | null
          address?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_type?: 'wholesaler' | 'retailer' | 'customer'
          first_name?: string
          last_name?: string
          email?: string
          phone?: string | null
          address?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      wholesalers: {
        Row: {
          id: string
          company_name: string
          industry_type: string
          business_address: string
        }
        Insert: {
          id: string
          company_name?: string
          industry_type?: string
          business_address?: string
        }
        Update: {
          id?: string
          company_name?: string
          industry_type?: string
          business_address?: string
        }
      }
      retailers: {
        Row: {
          id: string
          business_name: string
          business_type: string
          business_address: string
        }
        Insert: {
          id: string
          business_name?: string
          business_type?: string
          business_address?: string
        }
        Update: {
          id?: string
          business_name?: string
          business_type?: string
          business_address?: string
        }
      }
      customers: {
        Row: {
          id: string
          default_shipping_address: string | null
        }
        Insert: {
          id: string
          default_shipping_address?: string | null
        }
        Update: {
          id?: string
          default_shipping_address?: string | null
        }
      }
    }
  }
}