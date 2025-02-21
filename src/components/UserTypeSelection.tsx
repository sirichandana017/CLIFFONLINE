import React, { useState } from 'react';
import { Store, Users, ShoppingBag } from 'lucide-react';
import { AuthForm } from './AuthForm';

const userTypes = [
  {
    id: 'wholesaler',
    title: 'Wholesaler',
    description: 'Register as a wholesaler to sell products in bulk to retailers',
    icon: Store,
    color: 'blue',
    path: '/wholesaler',
  },
  {
    id: 'retailer',
    title: 'Retailer',
    description: 'Register as a retailer to buy from wholesalers and sell to customers',
    icon: Users,
    color: 'blue',
    path: '/retailer',
  },
  {
    id: 'customer',
    title: 'Everyday Shopper',
    description: 'Shop from a wide range of products from various retailers',
    icon: ShoppingBag,
    color: 'blue',
    path: '/customer',
  },
];

export function UserTypeSelection() {
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [showAuth, setShowAuth] = useState(false);

  const handleTypeSelect = (typeId: string) => {
    setSelectedType(typeId);
    // Update the URL to reflect the selected user type
    window.history.pushState({}, '', userTypes.find(t => t.id === typeId)?.path || '/');
    setTimeout(() => setShowAuth(true), 300); // Show auth form after transition
  };

  if (showAuth) {
    const selectedUserType = userTypes.find(t => t.id === selectedType);
    return (
      <div className="w-full max-w-md p-6 bg-white rounded-xl shadow-lg">
        <button
          onClick={() => {
            setShowAuth(false);
            setSelectedType(null);
            window.history.pushState({}, '', '/');
          }}
          className="mb-4 text-sm text-gray-500 hover:text-gray-700 flex items-center"
        >
          ← Back to user selection
        </button>
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {selectedUserType?.title} Registration
        </h2>
        <AuthForm />
      </div>
    );
  }

  return (
    <div className="w-full max-w-4xl">
      <div className="text-center mb-12">
        <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
          Welcome to MarketConnect
        </h2>
        <p className="mt-3 text-xl text-gray-500">
          Choose how you'd like to use our platform
        </p>
      </div>

      <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
        {userTypes.map((type) => {
          const Icon = type.icon;
          const isSelected = selectedType === type.id;
          const isHidden = selectedType && selectedType !== type.id;

          return (
            <div
              key={type.id}
              className={`relative group bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden ${
                isHidden ? 'opacity-0 scale-95' : 'opacity-100 scale-100'
              }`}
            >
              <div className="p-6">
                <div className="inline-flex items-center justify-center p-3 rounded-lg bg-blue-100 text-blue-600 mb-5">
                  <Icon className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {type.title}
                </h3>
                <p className="text-gray-500 mb-4">
                  {type.description}
                </p>
                <div className="space-y-3">
                  <button
                    onClick={() => handleTypeSelect(type.id)}
                    className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Get Started
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}