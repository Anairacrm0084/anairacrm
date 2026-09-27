import "./globals.css";

export const metadata = {
  title: "Anaira CRM — Hotel & Restaurant Intelligence",
  description: "Premium Customer 360 and Revenue Management"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
