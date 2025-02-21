import React, { useState, useEffect } from 'react';
import { Plus, Calendar, DollarSign, Tag } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';

interface Advertisement {
  id: string;
  product_id: string;
  discount: number;
  promotion_details: string;
  start_date: string;
  end_date: string;
  product: {
    name: string;
    price: number;
    images: string[];
  };
}

interface AdvertisingPlatformProps {
  userId: string;
  industryType: string;
}

export function AdvertisingPlatform({ userId, industryType }: AdvertisingPlatformProps) {
  const [advertisements, setAdvertisements] = useState<Advertisement[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  useEffect(() => {
    loadAdvertisements();
  }, []);

  const loadAdvertisements = async () => {
    try {
      const { data, error } = await supabase
        .from('advertisements')
        .select(`
          *,
          product:products (
            name,
            price,
            images
          )
        `)
        .eq('user_id', userId);

      if (error) throw error;
      setAdvertisements(data || []);
    } catch (error) {
      console.error('Error loading advertisements:', error);
      toast.error('Failed to load advertisements');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-lg font-medium text-gray-900">Active Promotions</h3>
          <p className="mt-1 text-sm text-gray-500">
            Create and manage promotional campaigns for your products
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <Plus className="h-5 w-5 mr-2" />
          New Promotion
        </button>
      </div>

      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
        </div>
      ) : advertisements.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg border border-gray-200">
          <Tag className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No active promotions</h3>
          <p className="mt-1 text-sm text-gray-500">
            Get started by creating a new promotional campaign
          </p>
          <div className="mt-6">
            <button
              onClick={() => setShowAddModal(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <Plus className="h-5 w-5 mr-2" />
              New Promotion
            </button>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {advertisements.map((ad) => (
            <div
              key={ad.id}
              className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden"
            >
              {ad.product.images && ad.product.images[0] && (
                <img
                  src={ad.product.images[0]}
                  alt={ad.product.name}
                  className="w-full h-48 object-cover"
                />
              )}
              <div className="p-6">
                <h4 className="text-lg font-semibold text-gray-900">{ad.product.name}</h4>
                <div className="mt-4 space-y-3">
                  <div className="flex items-center text-sm">
                    <DollarSign className="h-5 w-5 text-gray-400 mr-2" />
                    <span className="text-gray-500">Discount:</span>
                    <span className="ml-auto font-medium text-green-600">
                      {ad.discount}% OFF
                    </span>
                  </div>
                  <div className="flex items-center text-sm">
                    <Calendar className="h-5 w-5 text-gray-400 mr-2" />
                    <span className="text-gray-500">Valid until:</span>
                    <span className="ml-auto font-medium">
                      {new Date(ad.end_date).toLocaleDateString()}
                    </span>
                  </div>
                </div>
                <p className="mt-4 text-sm text-gray-600">{ad.promotion_details}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Promotion Modal would go here */}
    </div>
  );
}