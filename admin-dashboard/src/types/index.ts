export type OrderStatus =
  | "PENDING"
  | "CONFIRMED"
  | "IN_KITCHEN"
  | "READY"
  | "OUT_FOR_DELIVERY"
  | "DELIVERED"
  | "CANCELED";

export type OrderType = "DELIVERY" | "TAKEAWAY";

export interface SelectedOption {
  id?: string;
  name: string;
  price: number;
}

export interface OrderItem {
  id: string;
  name: string;
  image: string;
  quantity: number;
  price: number;
  selectedOptions: SelectedOption[];
}

export interface Order {
  id: string;
  orderType: OrderType;
  status: OrderStatus;
  totalPrice: number;
  deliveryAddress: string | null;
  notes: string | null;
  createdAt: string;
  customer: { name: string; phone: string; email: string };
  items: OrderItem[];
}

export interface OptionItem {
  id: string;
  name: string;
  price: number;
  position: number;
}

export interface OptionGroup {
  id: string;
  name: string;
  isRequired: boolean;
  allowMultiple: boolean;
  position: number;
  options: OptionItem[];
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string;
  categoryId: string;
  categoryName: string;
  isAvailable: boolean;
  position: number;
  optionGroups: OptionGroup[];
}

export interface Category {
  id: string;
  name: string;
  image: string;
  position: number;
  itemsCount?: number;
}

export interface TopProduct {
  name: string;
  quantity: number;
  revenue: number;
}

export interface SalesPoint {
  date: string;
  sales: number;
  orders: number;
}

export interface Stats {
  todayOrders: number;
  totalSales: number;
  activeOrders: number;
  topProducts: TopProduct[];
  salesSeries: SalesPoint[];
}

export interface Settings {
  acceptOrders: boolean;
  deliveryEnabled: boolean;
  deliveryFee: number;
  restaurantName: string;
  phone: string;
}

export interface AdminUser {
  id?: string;
  name: string;
  email: string;
  role: string;
}

export interface OptionGroupInput {
  name: string;
  isRequired: boolean;
  allowMultiple: boolean;
  options: { name: string; price: number }[];
}

export interface Vendor {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar: string | null;
  role: string;
  restaurantName: string | null;
  vendorId: string;
  createdAt: string;
  _count?: { agentOrders: number };
}

export interface VendorInput {
  name: string;
  email: string;
  phone: string;
  password: string;
  restaurantName?: string;
  avatar?: string;
}

export interface DeliveryMan {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar: string | null;
  role: string;
  createdAt: string;
  _count?: { deliveryOrders: number };
}

export interface DeliveryManInput {
  name: string;
  email: string;
  phone: string;
  password: string;
  avatar?: string;
}
