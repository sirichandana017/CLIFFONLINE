import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Store, Users, ShoppingBag } from 'lucide-react';

const userTypes = [
  {
    id: 'wholesaler',
    title: 'Wholesaler',
    description: 'Register as a wholesaler to sell products in bulk to retailers',
    icon: Store,
    color: 'blue',
  },
  {
    id: 'retailer',
    title: 'Retailer',
    description: 'Register as a retailer to buy from wholesalers and sell to customers',
    icon: Users,
    color: 'blue',
  },
  {
    id: 'customer',
    title: 'Everyday Shopper',
    description: 'Shop from a wide range of products from various retailers',
    icon: ShoppingBag,
    color: 'blue',
  },
];

export function HomePage() {
  const navigate = useNavigate();
  const [selectedType, setSelectedType] = React.useState<string | null>(null);

  const handleTypeSelect = (typeId: string) => {
    setSelectedType(typeId);
    setTimeout(() => {
      navigate(`/${typeId}/auth`);
    }, 300);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl lg:text-6xl">
            Welcome to MarketConnect
          </h1>
          <p className="mt-4 text-xl text-gray-600">
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
                className={`relative group bg-white rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 transform ${
                  isSelected ? 'scale-105' : 'hover:scale-105'
                } ${isHidden ? 'opacity-0 scale-95' : 'opacity-100'}`}
              >
                <div className="p-8">
                  <div className="inline-flex items-center justify-center p-3 bg-blue-100 rounded-lg text-blue-600 mb-5">
                    <Icon className="h-6 w-6" />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">
                    {type.title}
                  </h3>
                  <p className="text-gray-500 mb-6">
                    {type.description}
                  </p>
                  <button
                    onClick={() => handleTypeSelect(type.id)}
                    className="w-full py-3 px-4 rounded-lg bg-blue-600 text-white font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    Get Started
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}