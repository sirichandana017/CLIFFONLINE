import React, { useState } from 'react';
import { Menu, X, Package, Megaphone, BarChart2, ShoppingCart, ChevronLeft } from 'lucide-react';
import { InventoryManager } from './InventoryManager';
import { AdvertisingPlatform } from './AdvertisingPlatform';
import { SalesAnalytics } from './SalesAnalytics';
import { OrderManagement } from './OrderManagement';

interface WholesalerDashboardProps {
  userData: any;
}

export function WholesalerDashboard({ userData }: WholesalerDashboardProps) {
  const [activeTab, setActiveTab] = useState('inventory');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const tabs = [
    { id: 'inventory', name: 'Inventory', icon: Package },
    { id: 'advertising', name: 'Advertising', icon: Megaphone },
    { id: 'analytics', name: 'Analytics', icon: BarChart2 },
    { id: 'orders', name: 'Orders', icon: ShoppingCart },
  ];

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      {/* Sidebar */}
      <div 
        className={`fixed inset-y-0 left-0 transform ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } w-64 bg-white border-r border-gray-200 transition-transform duration-200 ease-in-out z-30 pt-16`}
      >
        <div className="h-full flex flex-col">
          <div className="flex items-center justify-between p-4">
            <h2 className="text-xl font-semibold text-gray-800">Dashboard</h2>
            <button
              onClick={() => setSidebarOpen(false)}
              className="p-2 rounded-md hover:bg-gray-100"
            >
              <X className="h-5 w-5 text-gray-500" />
            </button>
          </div>
          <nav className="flex-1 px-2 py-4 space-y-1">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-md transition-colors ${
                    activeTab === tab.id
                      ? 'bg-blue-50 text-blue-700'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <Icon className="h-5 w-5 mr-3" />
                  {tab.name}
                </button>
              );
            })}
          </nav>
          <div className="p-4 border-t border-gray-200">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                  <span className="text-blue-700 font-semibold">
                    {userData.profile.first_name[0]}
                  </span>
                </div>
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-700">
                  {userData.profile.first_name} {userData.profile.last_name}
                </p>
                <p className="text-xs text-gray-500">{userData.profile.email}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className={`flex-1 ${sidebarOpen ? 'ml-64' : 'ml-0'} transition-margin duration-200 ease-in-out`}>
        {!sidebarOpen && (
          <button
            onClick={() => setSidebarOpen(true)}
            className="fixed top-20 left-4 p-2 rounded-md bg-white shadow-md hover:bg-gray-50 z-20"
          >
            <Menu className="h-5 w-5 text-gray-600" />
          </button>
        )}
        <div className="p-8">
          {activeTab === 'inventory' && <InventoryManager userId={userData.id} />}
          {activeTab === 'advertising' && (
            <AdvertisingPlatform 
              userId={userData.id} 
              industryType={userData.profile.industry_type} 
            />
          )}
          {activeTab === 'analytics' && <SalesAnalytics userId={userData.id} />}
          {activeTab === 'orders' && <OrderManagement userId={userData.id} />}
        </div>
      </div>
    </div>
  );
}