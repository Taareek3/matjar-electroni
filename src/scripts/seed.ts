import bcrypt from "bcryptjs";
import { prisma } from "../config/database";
import { OrderStatus, OrderType, Role } from "../generated/prisma/client";

interface SeedOption {
  name: string;
  price: number;
}

interface SeedGroup {
  name: string;
  isRequired: boolean;
  allowMultiple: boolean;
  position: number;
  options: SeedOption[];
}

interface SeedItem {
  id: string;
  name: string;
  description: string;
  basePrice: number;
  image: string;
  position: number;
  groups: SeedGroup[];
}

interface SeedCategory {
  id: string;
  name: string;
  position: number;
  items: SeedItem[];
}

const pizzaSize: Omit<SeedGroup, "position"> = {
  name: "حجم البيتزا",
  isRequired: true,
  allowMultiple: false,
  options: [
    { name: "متوسط (30 سم)", price: 0 },
    { name: "كبير (40 سم)", price: 3 },
    { name: "عائلية (50 سم)", price: 5 },
  ],
};

const extraCheese: Omit<SeedGroup, "position"> = {
  name: "الجبن الإضافي",
  isRequired: false,
  allowMultiple: true,
  options: [
    { name: "جبنة موزاريلا إضافية", price: 0.5 },
    { name: "جبنة شيدر", price: 0.75 },
  ],
};

const sauces: Omit<SeedGroup, "position"> = {
  name: "الصوصات الإضافية",
  isRequired: false,
  allowMultiple: true,
  options: [
    { name: "صوص ثوم", price: 0.25 },
    { name: "صوص حار", price: 0.35 },
    { name: "صوص باربكيو", price: 0.5 },
  ],
};

const drinkSize: Omit<SeedGroup, "position"> = {
  name: "حجم المشروب",
  isRequired: true,
  allowMultiple: false,
  options: [
    { name: "صغير", price: 0 },
    { name: "كبير", price: 1 },
  ],
};

const burgerExtras: Omit<SeedGroup, "position"> = {
  name: "إضافات البرغر",
  isRequired: false,
  allowMultiple: true,
  options: [
    { name: "جبنة إضافية", price: 0.5 },
    { name: "بيكون مقرمش", price: 1.5 },
    { name: "صوص الدايز الخاص", price: 0.5 },
  ],
};

const friesSauces: Omit<SeedGroup, "position"> = {
  name: "الصوصات",
  isRequired: false,
  allowMultiple: true,
  options: [
    { name: "كاتشب", price: 0.2 },
    { name: "مايونيز", price: 0.2 },
  ],
};

const dessertExtras: Omit<SeedGroup, "position"> = {
  name: "إضافات الحلو",
  isRequired: false,
  allowMultiple: true,
  options: [
    { name: "كرة آيس كريم", price: 1.5 },
    { name: "صوص شوكولاتة", price: 0.75 },
  ],
};

function at(template: Omit<SeedGroup, "position">, position: number): SeedGroup {
  return { ...template, position };
}

const seedData: SeedCategory[] = [
  {
    id: "main",
    name: "وجبات رئيسية",
    position: 0,
    items: [
      {
        id: "m-main-grilled-chicken",
        name: "دجاج مشوي",
        description: "صدور دجاج متبّلة بالأعشاب مع أرز بالسمن وسلطة طازجة",
        basePrice: 11.49,
        image:
          "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=600&q=70",
        position: 0,
        groups: [at(sauces, 0), at(extraCheese, 1)],
      },
      {
        id: "m-main-pasta-alfredo",
        name: "معكرونة ألفريدو",
        description: "معكرونة فتوتشيني بصلصة الكريمة والبارميزان مع الفطر",
        basePrice: 9.49,
        image:
          "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=70",
        position: 1,
        groups: [at(extraCheese, 0), at(sauces, 1)],
      },
      {
        id: "m-main-fries",
        name: "بطاطس مقلية",
        description: "بطاطس ذهبية مقرمشة مقلية طازجة مع صوصات المطعم",
        basePrice: 3.29,
        image:
          "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&q=70",
        position: 2,
        groups: [at(friesSauces, 0)],
      },
    ],
  },
  {
    id: "pizza",
    name: "بيتزا",
    position: 1,
    items: [
      {
        id: "m-pizza-margherita",
        name: "بيتزا مارغريتا",
        description: "صلصة طماطم إيطالية، جبنة موزاريلا طازجة وريحان طازج",
        basePrice: 8.99,
        image:
          "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=70",
        position: 3,
        groups: [at(pizzaSize, 0), at(extraCheese, 1), at(sauces, 2)],
      },
      {
        id: "m-pizza-pepperoni",
        name: "بيتزا بيبروني",
        description: "شرائح بيبروني مقرمشة فوق طبقة غنية من الموزاريلا",
        basePrice: 10.99,
        image:
          "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&q=70",
        position: 4,
        groups: [at(pizzaSize, 0), at(extraCheese, 1), at(sauces, 2)],
      },
    ],
  },
  {
    id: "burger",
    name: "برغر",
    position: 2,
    items: [
      {
        id: "m-burger-classic",
        name: "برغر كلاسيك",
        description: "لحم طازج مشوي، خس، طماطم وصوص الدايز السري",
        basePrice: 7.49,
        image:
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=70",
        position: 5,
        groups: [at(burgerExtras, 0), at(sauces, 1)],
      },
      {
        id: "m-burger-double",
        name: "برغر دوبل تشيز",
        description: "قطعتا لحم مشوي مع جبنة شيدر ذائبة وحلقات بصل مقرمشة",
        basePrice: 9.99,
        image:
          "https://images.unsplash.com/photo-1550547660-d9450f859349?w=600&q=70",
        position: 6,
        groups: [at(burgerExtras, 0), at(sauces, 1)],
      },
    ],
  },
  {
    id: "drinks",
    name: "مشروبات",
    position: 3,
    items: [
      {
        id: "m-drink-orange-juice",
        name: "عصير برتقال طازج",
        description: "عصير طبيعي 100% معصور يومياً بدون أي سكر مضاف",
        basePrice: 3.49,
        image:
          "https://images.unsplash.com/photo-1613478223719-2ab802602423?w=600&q=70",
        position: 7,
        groups: [at(drinkSize, 0)],
      },
      {
        id: "m-drink-latte",
        name: "قهوة لاتيه",
        description: "إسبريسو مزدوج مع حليب مخفوق ورسم لاتيه فني",
        basePrice: 3.99,
        image:
          "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=70",
        position: 8,
        groups: [at(drinkSize, 0)],
      },
      {
        id: "m-drink-cola",
        name: "مشروب غازي",
        description: "كولا مبردة بحجم العلبة 400 مل",
        basePrice: 1.99,
        image:
          "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=600&q=70",
        position: 9,
        groups: [],
      },
    ],
  },
  {
    id: "desserts",
    name: "حلويات",
    position: 4,
    items: [
      {
        id: "m-dessert-choco-cake",
        name: "كيكة الشوكولاتة الساخنة",
        description: "كيكة شوكولاتة دافئة بقلب سائل وصوص شوكولاتة غني",
        basePrice: 4.99,
        image:
          "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&q=70",
        position: 10,
        groups: [at(dessertExtras, 0)],
      },
      {
        id: "m-dessert-ice-cream",
        name: "آيس كريم فانيليا",
        description: "كرات آيس كريم فانيليا بلجيكية مع صوص شوكولاتة",
        basePrice: 3.99,
        image:
          "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600&q=70",
        position: 11,
        groups: [],
      },
    ],
  },
];

async function seed(): Promise<void> {
  console.log("🌱 Seeding menu data...");

  await prisma.category.deleteMany({});

  let itemCount = 0;
  let groupCount = 0;
  let optionCount = 0;
  for (const category of seedData) {
    await prisma.category.create({
      data: {
        id: category.id,
        name: category.name,
        position: category.position,
        items: {
          create: category.items.map((item) => {
            itemCount += 1;
            return {
              id: item.id,
              name: item.name,
              description: item.description,
              basePrice: item.basePrice,
              image: item.image,
              isAvailable: true,
              position: item.position,
              optionGroups: {
                create: item.groups.map((group) => {
                  groupCount += 1;
                  return {
                    name: group.name,
                    isRequired: group.isRequired,
                    allowMultiple: group.allowMultiple,
                    position: group.position,
                    options: {
                      create: group.options.map((option, index) => {
                        optionCount += 1;
                        return {
                          name: option.name,
                          price: option.price,
                          position: index,
                        };
                      }),
                    },
                  };
                }),
              },
            };
          }),
        },
      },
    });
  }

  console.log(
    `✅ Seeded ${seedData.length} categories, ${itemCount} items, ${groupCount} option groups, ${optionCount} options`,
  );

  await seedAdmin();
  await seedSettings();
  await seedSampleOrders();
}

async function seedAdmin(): Promise<void> {
  const email = "taareek31@gmail.com";
  const password = "tarek1122334455";
  const hashed = await bcrypt.hash(password, 10);

  await prisma.user.upsert({
    where: { email },
    create: {
      email,
      name: "مدير النظام",
      firstName: "مدير",
      lastName: "النظام",
      password: hashed,
      role: Role.ADMIN,
      phone: "0912345678",
      country: "السعودية",
      city: "الرياض",
      addressLine: "شارع الملك فهد",
    },
    update: {
      password: hashed,
      role: Role.ADMIN,
      firstName: "مدير",
      lastName: "النظام",
    },
  });

  const customerEmail = "customer@binaflow.com";
  const customerHash = await bcrypt.hash("customer123", 10);

  await prisma.user.upsert({
    where: { email: customerEmail },
    create: {
      email: customerEmail,
      name: "عميل تجريبي",
      firstName: "عميل",
      lastName: "تجريبي",
      password: customerHash,
      role: Role.CUSTOMER,
      phone: "0911111111",
      country: "السعودية",
      city: "جدة",
      addressLine: "حي الروضة، شارع 8",
    },
    update: {
      password: customerHash,
      firstName: "عميل",
      lastName: "تجريبي",
      country: "السعودية",
      city: "جدة",
      addressLine: "حي الروضة، شارع 8",
      phone: "0911111111",
    },
  });

  console.log(`👤 Admin: ${email} / ${password}`);
}

async function seedSettings(): Promise<void> {
  const defaults: Record<string, string> = {
    acceptOrders: "true",
    deliveryEnabled: "true",
    deliveryFee: "2.99",
    restaurantName: "مطعم بينا فلاو",
    phone: "0912345678",
  };

  for (const [key, value] of Object.entries(defaults)) {
    await prisma.setting.upsert({
      where: { key },
      create: { key, value },
      update: {},
    });
  }

  console.log("⚙️  Settings seeded");
}

async function seedSampleOrders(): Promise<void> {
  const customer = await prisma.user.findUnique({
    where: { email: "customer@binaflow.com" },
  });

  if (!customer) return;

  const items = await prisma.menuItem.findMany({
    where: { isAvailable: true },
    include: { optionGroups: { include: { options: true } } },
  });

  if (items.length === 0) return;

  await prisma.order.deleteMany({ where: { userId: customer.id } });

  const sample: {
    hoursAgo: number;
    type: OrderType;
    status: OrderStatus;
    pick: number[];
    address?: string;
    notes?: string;
  }[] = [
    { hoursAgo: 1, type: OrderType.DELIVERY, status: OrderStatus.PENDING, pick: [0, 3], address: "شارع النور 12، الطابق 3", notes: "بدون بصل" },
    { hoursAgo: 2, type: OrderType.TAKEAWAY, status: OrderStatus.CONFIRMED, pick: [4, 7] },
    { hoursAgo: 3, type: OrderType.DELIVERY, status: OrderStatus.IN_KITCHEN, pick: [1, 5, 8], address: "حي الزهور، فيلا 8" },
    { hoursAgo: 5, type: OrderType.DELIVERY, status: OrderStatus.READY, pick: [2, 9], address: "شارع الجامعة 45" },
    { hoursAgo: 7, type: OrderType.TAKEAWAY, status: OrderStatus.OUT_FOR_DELIVERY, pick: [6, 10] },
    { hoursAgo: 26, type: OrderType.DELIVERY, status: OrderStatus.DELIVERED, pick: [0, 4, 7], address: "شارع النور 12" },
    { hoursAgo: 30, type: OrderType.TAKEAWAY, status: OrderStatus.DELIVERED, pick: [3, 5] },
    { hoursAgo: 50, type: OrderType.DELIVERY, status: OrderStatus.CANCELED, pick: [1, 8], address: "حي السلام 3" },
    { hoursAgo: 74, type: OrderType.DELIVERY, status: OrderStatus.DELIVERED, pick: [0, 1, 2], address: "شارع المدارس 9", notes: "توصيل سريع من فضلك" },
    { hoursAgo: 96, type: OrderType.TAKEAWAY, status: OrderStatus.DELIVERED, pick: [4, 6, 9] },
    { hoursAgo: 120, type: OrderType.DELIVERY, status: OrderStatus.DELIVERED, pick: [3, 7, 10], address: "حي الياسمين 21" },
    { hoursAgo: 144, type: OrderType.TAKEAWAY, status: OrderStatus.DELIVERED, pick: [5, 8] },
  ];

  let created = 0;

  for (const order of sample) {
    const orderItems = order.pick
      .map((index) => items[index % items.length])
      .filter(Boolean)
      .map((item) => {
        const quantity = 1 + (created % 3);
        const options = item.optionGroups.flatMap((group) =>
          group.isRequired ? [group.options[0]] : [],
        );
        const optionsPrice = options.reduce(
          (sum, option) => sum + option.price,
          0,
        );
        return {
          menuItemId: item.id,
          quantity,
          price: item.basePrice + optionsPrice,
          selectedOptions: options.map((option) => ({
            id: option.id,
            name: option.name,
            price: option.price,
          })),
        };
      });

    if (orderItems.length === 0) continue;

    const total = orderItems.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );

    await prisma.order.create({
      data: {
        userId: customer.id,
        orderType: order.type,
        status: order.status,
        totalPrice: Math.round(total * 100) / 100,
        deliveryAddress: order.address ?? null,
        notes: order.notes ?? null,
        createdAt: new Date(Date.now() - order.hoursAgo * 3600_000),
        items: { create: orderItems },
      },
    });

    created += 1;
  }

  console.log(`🧾 Seeded ${created} sample orders`);
}

seed()
  .then(() => prisma.$disconnect())
  .catch(async (error: unknown) => {
    console.error("❌ Seed failed:", error);
    await prisma.$disconnect();
    process.exit(1);
  });
