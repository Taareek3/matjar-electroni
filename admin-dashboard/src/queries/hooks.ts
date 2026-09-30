import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { api, type ApiEnvelope } from "../lib/api";
import type {
  Category,
  DeliveryMan,
  DeliveryManInput,
  MenuItem,
  OptionGroup,
  OptionGroupInput,
  Order,
  OrderStatus,
  Settings,
  Stats,
  Vendor,
  VendorInput,
} from "../types";

async function request<T>(url: string): Promise<T> {
  const { data } = await api.get<ApiEnvelope<T>>(url);
  return data.data;
}

// ---------------- الإحصائيات ----------------

export function useStats() {
  return useQuery<Stats>({
    queryKey: ["stats"],
    queryFn: () => request<Stats>("/admin/stats"),
    refetchInterval: 30_000,
  });
}

// ---------------- الطلبات ----------------

export function useOrders(status?: OrderStatus) {
  return useQuery<{ orders: Order[] }>({
    queryKey: ["orders", status ?? "all"],
    queryFn: () =>
      request<{ orders: Order[] }>(
        status ? `/admin/orders?status=${status}` : "/admin/orders",
      ),
    refetchInterval: 5_000,
  });
}

export function useUpdateOrderStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      id,
      status,
    }: {
      id: string;
      status: OrderStatus;
    }) => {
      const { data } = await api.patch<ApiEnvelope<unknown>>(
        `/admin/orders/${id}/status`,
        { status },
      );
      return data;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["orders"] });
      void queryClient.invalidateQueries({ queryKey: ["stats"] });
    },
  });
}

// ---------------- المنيو ----------------

export interface AdminMenuData {
  categories: Category[];
  items: MenuItem[];
}

export function useAdminMenu() {
  return useQuery<AdminMenuData>({
    queryKey: ["admin-menu"],
    queryFn: () => request<AdminMenuData>("/admin/menu"),
  });
}

export interface MenuItemInput {
  name: string;
  description: string;
  price: number;
  image: string;
  categoryId: string;
  isAvailable?: boolean;
  position?: number;
}

function useInvalidateMenu() {
  const queryClient = useQueryClient();
  return () => {
    void queryClient.invalidateQueries({ queryKey: ["admin-menu"] });
    void queryClient.invalidateQueries({ queryKey: ["categories"] });
    void queryClient.invalidateQueries({ queryKey: ["menu"] });
  };
}

export function useCreateMenuItem() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (input: MenuItemInput) => {
      const { data } = await api.post<ApiEnvelope<{ item: MenuItem }>>(
        "/admin/menu/items",
        input,
      );
      return data.data.item;
    },
    onSuccess: invalidate,
  });
}

export function useUpdateMenuItem() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async ({
      id,
      input,
    }: {
      id: string;
      input: MenuItemInput;
    }) => {
      const { data } = await api.put<ApiEnvelope<{ item: MenuItem }>>(
        `/admin/menu/items/${id}`,
        input,
      );
      return data.data.item;
    },
    onSuccess: invalidate,
  });
}

export function useSetAvailability() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async ({
      id,
      isAvailable,
    }: {
      id: string;
      isAvailable: boolean;
    }) => {
      const { data } = await api.patch<ApiEnvelope<unknown>>(
        `/admin/menu/items/${id}/availability`,
        { isAvailable },
      );
      return data;
    },
    onSuccess: invalidate,
  });
}

export function useDeleteMenuItem() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.delete<ApiEnvelope<unknown>>(
        `/admin/menu/items/${id}`,
      );
      return data;
    },
    onSuccess: invalidate,
  });
}

export function useCreateOptionGroup() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async ({
      itemId,
      input,
    }: {
      itemId: string;
      input: OptionGroupInput;
    }) => {
      const { data } = await api.post<ApiEnvelope<{ group: OptionGroup }>>(
        `/admin/menu/items/${itemId}/groups`,
        input,
      );
      return data.data.group;
    },
    onSuccess: invalidate,
  });
}

export function useUpdateOptionGroup() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async ({
      groupId,
      input,
    }: {
      groupId: string;
      input: OptionGroupInput;
    }) => {
      const { data } = await api.put<ApiEnvelope<{ group: OptionGroup }>>(
        `/admin/menu/groups/${groupId}`,
        input,
      );
      return data.data.group;
    },
    onSuccess: invalidate,
  });
}

export function useDeleteOptionGroup() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (groupId: string) => {
      const { data } = await api.delete<ApiEnvelope<unknown>>(
        `/admin/menu/groups/${groupId}`,
      );
      return data;
    },
    onSuccess: invalidate,
  });
}

// ---------------- الأقسام ----------------

export function useCategories() {
  return useQuery<{ categories: Category[] }>({
    queryKey: ["categories"],
    queryFn: () => request<{ categories: Category[] }>("/admin/categories"),
  });
}

export function useCreateCategory() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (input: { name: string; image?: string }) => {
      const { data } = await api.post<ApiEnvelope<{ category: Category }>>(
        "/admin/categories",
        input,
      );
      return data.data.category;
    },
    onSuccess: invalidate,
  });
}

export function useUpdateCategory() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async ({
      id,
      input,
    }: {
      id: string;
      input: { name: string; image?: string };
    }) => {
      const { data } = await api.put<ApiEnvelope<{ category: Category }>>(
        `/admin/categories/${id}`,
        input,
      );
      return data.data.category;
    },
    onSuccess: invalidate,
  });
}

export function useDeleteCategory() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.delete<ApiEnvelope<unknown>>(
        `/admin/categories/${id}`,
      );
      return data;
    },
    onSuccess: invalidate,
  });
}

export function useReorderCategories() {
  const invalidate = useInvalidateMenu();
  return useMutation({
    mutationFn: async (ids: string[]) => {
      const { data } = await api.patch<ApiEnvelope<unknown>>(
        "/admin/categories/reorder",
        { ids },
      );
      return data;
    },
    onSuccess: invalidate,
  });
}

// ---------------- الوكلاء (Vendors) ----------------

export function useVendors() {
  return useQuery<{ vendors: Vendor[] }>({
    queryKey: ["vendors"],
    queryFn: () => request<{ vendors: Vendor[] }>("/admin/vendors"),
    retry: 1,
  });
}

export function useCreateVendor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: VendorInput) => {
      const { data } = await api.post<
        ApiEnvelope<{ vendor: Vendor; user: Vendor }>
      >("/admin/vendors", input);
      return data.data.vendor;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["vendors"] });
    },
  });
}

export function useUpdateVendor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      input,
    }: {
      id: string;
      input: Partial<VendorInput>;
    }) => {
      const { data } = await api.put<ApiEnvelope<{ vendor: Vendor }>>(
        `/admin/vendors/${id}`,
        input,
      );
      return data.data.vendor;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["vendors"] });
    },
  });
}

export function useDeleteVendor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.delete<ApiEnvelope<unknown>>(
        `/admin/vendors/${id}`,
      );
      return data;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["vendors"] });
    },
  });
}

// ---------------- عمال التوصيل (Delivery Men) ----------------

export function useDeliveryMen() {
  return useQuery<{ deliveryMen: DeliveryMan[] }>({
    queryKey: ["delivery-men"],
    queryFn: () => request<{ deliveryMen: DeliveryMan[] }>("/admin/delivery-men"),
    retry: 1,
  });
}

export function useCreateDeliveryMan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: DeliveryManInput) => {
      const { data } = await api.post<
        ApiEnvelope<{ deliveryMan: DeliveryMan; user: DeliveryMan }>
      >("/admin/delivery-men", input);
      return data.data.deliveryMan;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["delivery-men"] });
    },
  });
}

export function useUpdateDeliveryMan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      input,
    }: {
      id: string;
      input: Partial<DeliveryManInput>;
    }) => {
      const { data } = await api.put<ApiEnvelope<{ deliveryMan: DeliveryMan }>>(
        `/admin/delivery-men/${id}`,
        input,
      );
      return data.data.deliveryMan;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["delivery-men"] });
    },
  });
}

export function useDeleteDeliveryMan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.delete<ApiEnvelope<unknown>>(
        `/admin/delivery-men/${id}`,
      );
      return data;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["delivery-men"] });
    },
  });
}

// ---------------- الإعدادات ----------------

export function useSettings() {
  return useQuery<{ settings: Settings }>({
    queryKey: ["settings"],
    queryFn: () => request<{ settings: Settings }>("/admin/settings"),
  });
}

export function useUpdateSettings() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: Partial<Settings>) => {
      const { data } = await api.put<ApiEnvelope<{ settings: Settings }>>(
        "/admin/settings",
        input,
      );
      return data.data.settings;
    },
    onSuccess: (settings) => {
      queryClient.setQueryData(["settings"], { settings });
    },
  });
}
