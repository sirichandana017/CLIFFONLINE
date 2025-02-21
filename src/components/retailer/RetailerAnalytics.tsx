import React, { useState, useEffect } from 'react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import { Calendar, Filter } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';

interface SalesData {
  date: string;
  revenue: number;
  orders: number;
}

interface ProductPerformance {
  product_name: string;
  total_sales: number;
  revenue: number;
}

interface RetailerAnalyticsProps {
  userId: string;
}

export function RetailerAnalytics({ userId }: RetailerAnalyticsProps) {
  const [salesData, setSalesData] = useState<SalesData[]>([]);
  const [productPerformance, setProductPerformance] = useState<ProductPerformance[]>([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('7d'); // 7d, 30d, 90d, 1y
  const [selectedCategory, setSelectedCategory] = useState('all');

  useEffect(() => {
    loadAnalytics();
  }, [dateRange, selectedCategory]);

  const loadAnalytics = async () => {
    try {
      setLoading(true);

      // Load sales data
      const { data: sales, error: salesError } = await supabase
        .from('orders')
        .select(`
          created_at,
          total_price,
          order_items (
            quantity,
            product:products (
              name,
              category
            )
          )
        `)
        .eq('seller_id', userId)
        .gte('created_at', getDateRangeStart())
        .order('created_at', { ascending: true });

      if (salesError) throw salesError;

      // Process sales data
      const processedSales = processSalesData(sales);
      setSalesData(processedSales);

      // Process product performance
      const processedProducts = processProductPerformance(sales);
      setProductPerformance(processedProducts);
    } catch (error) {
      console.error('Error loading analytics:', error);
      toast.error('Failed to load analytics data');
    } finally {
      setLoading(false);
    }
  };

  const getDateRangeStart = () => {
    const now = new Date();
    switch (dateRange) {
      case '7d':
        return new Date(now.setDate(now.getDate() - 7)).toISOString();
      case '30d':
        return new Date(now.setDate(now.getDate() - 30)).toISOString();
      case '90d':
        return new Date(now.setDate(now.getDate() - 90)).toISOString();
      case '1y':
        return new Date(now.setFullYear(now.getFullYear() - 1)).toISOString();
      default:
        return new Date(now.setDate(now.getDate() - 7)).toISOString();
    }
  };

  const processSalesData = (sales: any[]): SalesData[] => {
    // Process sales data logic here
    return [];
  };

  const processProductPerformance = (sales: any[]): ProductPerformance[] => {
    // Process product performance logic here
    return [];
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-lg font-medium text-gray-900">Sales Analytics</h3>
          <p className="mt-1 text-sm text-gray-500">
            Track your sales performance and trends
          </p>
        </div>
        <div className="flex space-x-4">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
            <option value="90d">Last 90 days</option>
            <option value="1y">Last year</option>
          </select>
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
          >
            <option value="all">All Categories</option>
            {/* Add categories dynamically */}
          </select>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Revenue Trend */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Revenue Trend</h4>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={salesData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="revenue" stroke="#2563eb" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Product Performance */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Product Performance</h4>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={productPerformance}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="product_name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="total_sales" fill="#2563eb" />
                  <Bar dataKey="revenue" fill="#7c3aed" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}