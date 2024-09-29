require('dotenv').config(); // Load environment variables
const TelegramBot = require('node-telegram-bot-api');
const { ethers } = require('ethers');

// Initialize the bot
const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: true });

// Connect to the Neox blockchain
const provider = new ethers.providers.JsonRpcProvider(process.env.NEOX_RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Smart contract information
const contractAddress = process.env.CONTRACT_ADDRESS;
const contractABI = [ /* ABI from your deployed contract */ ];
const tokenContract = new ethers.Contract(contractAddress, contractABI, signer);

// Function to validate inputs
const isValidAddress = (address) => ethers.utils.isAddress(address);
const isPositiveInteger = (value) => Number.isInteger(value) && value > 0;

// Handle the /createToken command
bot.onText(/\/createToken (.+) (.+) (.+) (.+)/, async (msg, match) => {
    const chatId = msg.chat.id;
    const tokenName = match[1];
    const tokenSymbol = match[2];
    const quantity = parseInt(match[3], 10); // Quantity should be an integer
    const walletAddress = match[4];

    // Validate inputs
    if (!isValidAddress(walletAddress) || !isPositiveInteger(quantity)) {
        return bot.sendMessage(chatId, 'Invalid input! Please ensure the wallet address is valid and quantity is a positive integer.');
    }

    try {
        // Create the token
        const tx = await tokenContract.mint(walletAddress, ethers.utils.parseUnits(quantity.toString(), 18)); // Assuming 18 decimal places
        await tx.wait();
        bot.sendMessage(chatId, `Token created and sent to ${walletAddress}!`);
    } catch (error) {
        console.error('Error minting token:', error);
        bot.sendMessage(chatId, 'An error occurred while creating the token. Please try again later.');
    }
});
