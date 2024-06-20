import { Inter } from "next/font/google";
import Script from "next/script";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });
const metadata = {
    name: "Create Next App",
    description: "Generated by create next app",
    light: "#f5e8fc",
    dark: "#1b1a1f",
    header: "https://img-a.ryte.com/f/117064/c659b64f07/og-image-size-guide.png"
}

export default function RootLayout({ children }) {
	return (
		<html lang="en">
            <>
                <title>{ metadata.name }</title>
                <meta name="description" content={ metadata.description }/>
				<meta name="theme-color" media="(prefers-color-scheme: light)" content={ metadata.light } />
				<meta name="theme-color" media="(prefers-color-scheme: dark)" content={ metadata.dark } />
				<meta name="color-scheme" content="dark light"/>
				<link rel="manifest" href="/manifest.json"/>
                {/* Icons */}
				<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png"/>
				<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png"/>
				<link rel="shortctut icon" href="/favicon.ico"/>
				<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png"/>
				<link rel="mask-icon" href="/safari-pinned-tab.svg" color="#d016ff"/>
				<meta name="apple-mobile-web-app-title" content={ metadata.name }/>
				<meta name="application-name" content={ metadata.name }/>
				<meta name="msapplication-TileColor" content={ metadata.dark }/>
				{/* Open Graph (Facebook) */}
				<meta property="og:title" content={ metadata.title }/>
				<meta property="og:description" content={ metadata.description }/>
				<meta property="og:image" content={ metadata.header } />
				<meta property="og:image:alt" content="Default image" />
				{/* X (Twitter) */}
				<meta name="twitter:card" content="summary_large_image"/>
				<meta name="twitter:url" content="https://localhost/?src=twitter" />
				<meta name="twitter:title" content={ metadata.title } />
				<meta name="twitter:description" content={ metadata.description }/>
				<meta name="twitter:image:src" content={ metadata.header } />
				<meta name="twitter:image:alt" content="Default image" />
            </>
			<body className={inter.className}>{children}</body>
            <Script 
				id="loadSW"
				dangerouslySetInnerHTML={{
					__html:`if('serviceWorker' in navigator) navigator.serviceWorker.register('/worker.js').catch(console.error);`
				}}
			/>
		</html>
	);
}
